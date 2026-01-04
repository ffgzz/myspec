import os
import sys
import shutil
import subprocess
import zipfile
import tempfile
import ssl
import json
from pathlib import Path
from typing import Optional, Tuple

import typer
import httpx
import readchar  # 用于捕获键盘输入
import truststore
from rich.console import Console
from rich.panel import Panel
from rich.live import Live
from rich.tree import Tree
from rich.table import Table
from rich.align import Align

# --- 配置常量 ---
REPO_OWNER = "github"
REPO_NAME = "spec-kit"
AI_ASSISTANT = "claude"
SCRIPT_TYPE_CHOICES = {"sh": "POSIX Shell (bash/zsh)", "ps": "PowerShell"}

ssl_context = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
client = httpx.Client(verify=ssl_context)

console = Console()
app = typer.Typer(help="My Custom SDD CLI Tool", add_completion=False)


# --- 交互辅助函数 (还原原版光标选择逻辑) ---

def get_key():
    """跨平台获取单个按键输入"""
    key = readchar.readkey()

    if key == readchar.key.UP or key == readchar.key.CTRL_P:
        return 'up'
    if key == readchar.key.DOWN or key == readchar.key.CTRL_N:
        return 'down'
    if key == readchar.key.ENTER:
        return 'enter'
    if key == readchar.key.ESC:
        return 'escape'
    if key == readchar.key.CTRL_C:
        raise KeyboardInterrupt
    return key


def select_with_arrows(options: dict, prompt_text: str = "Select an option", default_key: str = None) -> str:
    """
    使用 Rich Live 显示可交互的箭头选择菜单
    """
    option_keys = list(options.keys())
    if default_key and default_key in option_keys:
        selected_index = option_keys.index(default_key)
    else:
        selected_index = 0

    selected_key = None

    def create_selection_panel():
        """渲染选择面板"""
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", justify="left", width=3)
        table.add_column(style="white", justify="left")

        for i, key in enumerate(option_keys):
            label = options[key]
            if i == selected_index:
                # 选中状态：显示箭头，高亮
                table.add_row("▶", f"[cyan bold]{key}[/] [dim]({label})[/dim]")
            else:
                # 未选中状态
                table.add_row(" ", f"[white]{key}[/] [dim]({label})[/dim]")

        table.add_row("", "")
        table.add_row("", "[dim]Use ↑/↓ to navigate, Enter to select, Esc to cancel[/dim]")

        return Panel(
            table,
            title=f"[bold]{prompt_text}[/bold]",
            border_style="cyan",
            padding=(1, 2)
        )

    console.print()  # 空一行

    # 使用 Live 刷新界面
    with Live(create_selection_panel(), console=console, transient=True, auto_refresh=False) as live:
        while True:
            try:
                # 阻塞等待按键
                key = get_key()

                if key == 'up':
                    selected_index = (selected_index - 1) % len(option_keys)
                elif key == 'down':
                    selected_index = (selected_index + 1) % len(option_keys)
                elif key == 'enter':
                    selected_key = option_keys[selected_index]
                    break
                elif key == 'escape':
                    console.print("\n[yellow]Selection cancelled[/yellow]")
                    raise typer.Exit(1)

                live.update(create_selection_panel(), refresh=True)

            except KeyboardInterrupt:
                console.print("\n[yellow]Selection cancelled[/yellow]")
                raise typer.Exit(1)

    if selected_key is None:
        raise typer.Exit(1)

    return selected_key


# --- StepTracker (进度条组件) ---
class StepTracker:
    def __init__(self, title: str):
        self.title = title
        self.steps = []
        self._refresh_cb = None

    def attach_refresh(self, cb):
        self._refresh_cb = cb

    def add(self, key: str, label: str):
        if key not in [s["key"] for s in self.steps]:
            self.steps.append({"key": key, "label": label, "status": "pending", "detail": ""})
            self._maybe_refresh()

    def start(self, key: str, detail: str = ""):
        self._update(key, status="running", detail=detail)

    def complete(self, key: str, detail: str = ""):
        self._update(key, status="done", detail=detail)

    def error(self, key: str, detail: str = ""):
        self._update(key, status="error", detail=detail)

    def skip(self, key: str, detail: str = ""):
        self._update(key, status="skipped", detail=detail)

    def _update(self, key: str, status: str, detail: str):
        for s in self.steps:
            if s["key"] == key:
                s["status"] = status
                if detail: s["detail"] = detail
                self._maybe_refresh()
                return
        self.steps.append({"key": key, "label": key, "status": status, "detail": detail})
        self._maybe_refresh()

    def _maybe_refresh(self):
        if self._refresh_cb:
            try:
                self._refresh_cb()
            except:
                pass

    def render(self):
        tree = Tree(f"[cyan]{self.title}[/cyan]", guide_style="grey50")
        for step in self.steps:
            label = step["label"]
            detail = f" [dim]({step['detail']})[/dim]" if step['detail'] else ""
            status = step["status"]

            if status == "done":
                symbol = "[green]●[/green]"
            elif status == "pending":
                symbol = "[green dim]○[/green dim]"
            elif status == "running":
                symbol = "[cyan]○[/cyan]"
            elif status == "error":
                symbol = "[red]●[/red]"
            elif status == "skipped":
                symbol = "[yellow]○[/yellow]"
            else:
                symbol = " "

            style = "[bright_black]" if status == "pending" else "[white]"
            tree.add(f"{symbol} {style}{label}[/]{detail}")
        return tree


# --- 核心逻辑函数 ---

def check_tool(tool: str, tracker: StepTracker = None) -> bool:
    if tool == "claude":
        claude_local = Path.home() / ".claude" / "local" / "claude"
        if claude_local.exists():
            if tracker: tracker.complete(tool, "available (local)")
            return True

    found = shutil.which(tool) is not None
    if tracker:
        if found:
            tracker.complete(tool, "available")
        else:
            tracker.error(tool, "not found")
    return found


def init_git_repo(project_path: Path) -> bool:
    try:
        subprocess.run(["git", "init"], cwd=project_path, check=True, capture_output=True)
        subprocess.run(["git", "add", "."], cwd=project_path, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=project_path, check=True, capture_output=True)
        return True
    except Exception:
        return False


def download_template_from_github(download_dir: Path, script_type: str) -> Tuple[Path, dict]:
    api_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/releases/latest"
    resp = client.get(api_url, follow_redirects=True)
    if resp.status_code != 200:
        raise RuntimeError(f"GitHub API Error: {resp.status_code}")

    release_data = resp.json()
    assets = release_data.get("assets", [])
    pattern = f"spec-kit-template-{AI_ASSISTANT}-{script_type}"
    asset = next((a for a in assets if pattern in a["name"] and a["name"].endswith(".zip")), None)

    if not asset:
        raise RuntimeError(f"No asset found for pattern: {pattern}")

    download_url = asset["browser_download_url"]
    filename = asset["name"]
    zip_path = download_dir / filename

    with client.stream("GET", download_url, follow_redirects=True) as r:
        with open(zip_path, 'wb') as f:
            for chunk in r.iter_bytes():
                f.write(chunk)

    return zip_path, {"version": release_data["tag_name"], "filename": filename}


def extract_template(zip_path: Path, project_path: Path, is_current_dir: bool, tracker: StepTracker = None):
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        if is_current_dir:
            with tempfile.TemporaryDirectory() as temp_dir:
                zip_ref.extractall(temp_dir)
                temp_path = Path(temp_dir)
                items = list(temp_path.iterdir())
                source = items[0] if len(items) == 1 and items[0].is_dir() else temp_path
                for item in source.iterdir():
                    dest = project_path / item.name
                    if item.is_dir():
                        shutil.copytree(item, dest, dirs_exist_ok=True)
                    else:
                        shutil.copy2(item, dest)
        else:
            zip_ref.extractall(project_path)
            items = list(project_path.iterdir())
            if len(items) == 1 and items[0].is_dir():
                nested = items[0]
                temp_move = project_path.parent / f"{project_path.name}_temp"
                shutil.move(str(nested), str(temp_move))
                project_path.rmdir()
                shutil.move(str(temp_move), str(project_path))
                if tracker: tracker.complete("extract", "flattened nested dir")


def ensure_executable(project_path: Path):
    if os.name == "nt": return
    scripts_dir = project_path / ".specify" / "scripts"
    if scripts_dir.exists():
        for script in scripts_dir.rglob("*.sh"):
            try:
                os.chmod(script, script.stat().st_mode | 0o111)
            except:
                pass


# --- 命令定义 ---

@app.command()
def init(
        project_name: str = typer.Argument(None, help="Project name or '.' for current dir"),
        script: str = typer.Option(None, "--script", help="Script type: sh or ps"),
        here: bool = typer.Option(False, "--here", help="Init in current dir"),
        no_git: bool = typer.Option(False, "--no-git", help="Skip git init"),
):
    """Initialize a new project (Claude Code only)"""

    # 1. 路径处理
    if project_name == ".":
        here = True
        project_name = None

    if here:
        project_path = Path.cwd()
        if any(project_path.iterdir()) and not typer.confirm("Directory not empty. Continue?"):
            raise typer.Exit()
    elif project_name:
        project_path = Path(project_name).resolve()
        if project_path.exists():
            console.print(f"[red]Error:[/red] Directory {project_name} exists")
            raise typer.Exit(1)
        project_path.mkdir(parents=True)
    else:
        console.print("[red]Need project name or --here[/red]")
        raise typer.Exit(1)

    # 2. 脚本选择
    if script:
        # 如果用户通过命令行指定了 (如 --script sh)，则校验合法性
        if script not in SCRIPT_TYPE_CHOICES:
            console.print(
                f"[red]Error:[/red] Invalid script type '{script}'. Choose from: {', '.join(SCRIPT_TYPE_CHOICES.keys())}")
            raise typer.Exit(1)
        selected_script = script
    else:
        # 如果未指定，则进行交互式选择
        default_script = "ps" if os.name == "nt" else "sh"

        # 只有在标准终端下才显示交互菜单，管道模式下使用默认值
        if sys.stdin.isatty():
            selected_script = select_with_arrows(
                SCRIPT_TYPE_CHOICES,
                "Choose script type (or press Enter)",
                default_script
            )
        else:
            selected_script = default_script
            console.print(f"[yellow]Non-interactive mode detected. Using default script: {selected_script}[/yellow]")

    console.print(f"[cyan]Selected script type:[/cyan] {selected_script}")

    # 3. 执行流程
    tracker = StepTracker(f"Initializing {project_path.name}")
    tracker.add("env", "Environment Check")
    tracker.add("download", "Fetch Template")
    tracker.add("extract", "Extract Files")
    tracker.add("git", "Git Init")

    with Live(tracker.render(), console=console, refresh_per_second=4) as live:
        tracker.attach_refresh(lambda: live.update(tracker.render()))

        tracker.start("env")
        check_tool("claude", tracker)
        tracker.complete("env")

        tracker.start("download")
        try:
            zip_path, meta = download_template_from_github(Path.cwd(), selected_script)
            tracker.complete("download", f"v{meta['version']}")
        except Exception as e:
            tracker.error("download", str(e))
            raise typer.Exit(1)

        tracker.start("extract")
        try:
            extract_template(zip_path, project_path, here, tracker)
            if zip_path.exists(): zip_path.unlink()
            ensure_executable(project_path)
            tracker.complete("extract")
        except Exception as e:
            tracker.error("extract", str(e))
            raise typer.Exit(1)

        if not no_git and check_tool("git"):
            tracker.start("git")
            if init_git_repo(project_path):
                tracker.complete("git")
            else:
                tracker.error("git", "failed")
        else:
            tracker.skip("git")

    console.print(f"\n[bold green]Ready![/] Project initialized at {project_path}")


@app.command()
def check():
    """Check required tools"""
    console.print("[bold]Checking Tools...[/bold]\n")
    tracker = StepTracker("System Check")
    tracker.add("git", "Git")
    tracker.add("claude", "Claude Code")

    check_tool("git", tracker)
    check_tool("claude", tracker)
    console.print(tracker.render())


@app.command()
def version():
    """Show info"""
    table = Table(box=None, show_header=False)
    table.add_column("Key", style="cyan", justify="right")
    table.add_column("Value", style="white")
    table.add_row("CLI Version", "0.1.0 (Lite)")
    table.add_row("Template Source", f"{REPO_OWNER}/{REPO_NAME}")
    console.print(Panel(table, title="My Spec CLI", border_style="cyan"))


def main():
    app()


if __name__ == "__main__":
    main()