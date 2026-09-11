#!/usr/bin/env python3
"""教学用最小 Agent Loop —— 不需要 API key。

用一个写死脚本的「假模型」演示 loop 的核心机制：
模型报错 → 错误信息原样回灌上下文 → 模型下一轮自我修正。

对应文章《Day 1｜120 行代码读懂 Agent Loop》第 3 节。
真实版本见 miniharness 仓库的 agent.py（约 120 行逻辑 + 7 个工具）。
"""

# --- 两个「笨工具」：执行命令，报错不抛异常，原样返回 -------------------------

def run_command(cmd: str, env_has_python: bool = False) -> dict:
    """模拟 shell。env_has_python=False 时，python 命令报 127，和真实环境一样。"""
    if cmd.startswith("python ") and not env_has_python:
        return {"return_code": 127, "stderr": "/bin/sh: 1: python: not found"}
    if cmd.startswith("which "):
        return {"return_code": 0, "stdout": "/usr/bin/python3"}
    if cmd.startswith("python3 "):
        return {"return_code": 0, "stdout": "hello miniharness"}
    return {"return_code": 1, "stderr": f"unknown command: {cmd}"}

TOOLS = {"run_command": run_command}


# --- 假模型：一个按脚本出牌的「模型」，唯一输入是 context ---------------------

def fake_model(context: list) -> dict:
    """根据上下文里最近一次工具结果决定下一步。这就是「智能」栖身的地方。"""
    last = context[-1]
    # 看到 stderr 里有 not found -> 先探测环境（自我恢复从这一步涌现）
    if "not found" in last.get("stderr", ""):
        return {"tool_call": ("run_command", "which python3")}
    # 探测完 -> 改用 python3
    if last.get("stdout", "").endswith("python3"):
        return {"tool_call": ("run_command", "python3 greet.py")}
    # 看到正确输出 -> 宣布完成，退出 loop
    if "hello miniharness" in last.get("stdout", ""):
        return {"finish": "created and verified"}
    # 第一步：无条件先跑 python（会失败）
    return {"tool_call": ("run_command", "python greet.py")}


# --- Agent Loop：全部核心就在这里 ---------------------------------------------

def agent_loop(model, tools, task: str, max_iter: int = 10) -> list:
    context = [{"role": "user", "content": task}]
    for step in range(1, max_iter + 1):
        response = model(context)                    # 1. 模型看上下文，决定下一步
        if "finish" in response:                     # 2. 没有工具调用 -> 退出
            print(f"step {step}: finish  {response['finish']}")
            break
        name, arg = response["tool_call"]
        result = tools[name](arg)                    # 3. 执行工具
        print(f"step {step}: {name}  {arg}  -> {result}")
        context.append({"role": "tool", **result})   # 4. 结果原样回灌上下文
    return context


if __name__ == "__main__":
    agent_loop(fake_model, TOOLS, "创建 greet.py 并运行，确认输出 hello miniharness")
