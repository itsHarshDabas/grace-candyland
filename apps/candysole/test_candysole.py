import importlib.machinery
import importlib.util
import os

import pytest

SCRIPT = os.path.join(os.path.dirname(__file__), "candysole")


def load_module():
    loader = importlib.machinery.SourceFileLoader("candysole_module", SCRIPT)
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


candysole = load_module()


def test_hex_to_rgb():
    assert candysole.hex_to_rgb("#ec6271") == (236, 98, 113)
    assert candysole.hex_to_rgb("121419") == (18, 20, 25)
    assert candysole.hex_to_rgb("  #FFFFFF  ") == (255, 255, 255)


@pytest.mark.parametrize(
    "value",
    [None, "", "#12345", "#1234567", "not-a-color", "#gg0000"],
)
def test_hex_to_rgb_rejects_invalid_values(value):
    with pytest.raises(ValueError):
        candysole.hex_to_rgb(value)


def test_rgb_to_hex():
    assert candysole.rgb_to_hex((236, 98, 113)) == "#ec6271"
    assert candysole.rgb_to_hex((0, 0, 0)) == "#000000"


@pytest.mark.parametrize(
    "value",
    [(0, 0), (0, 0, 256), (0, 0, -1), (0, 0, 1.5), ("0", "0", "0")],
)
def test_rgb_to_hex_rejects_invalid_values(value):
    with pytest.raises(ValueError):
        candysole.rgb_to_hex(value)


def test_rgba_from_hex():
    assert candysole.rgba_from_hex("#ff8000") == pytest.approx(
        (1.0, 128 / 255.0, 0.0, 1.0)
    )
    assert candysole.rgba_from_hex("#000000", 0.5) == (
        0.0,
        0.0,
        0.0,
        0.5,
    )


@pytest.mark.parametrize("alpha", [-0.1, 1.1, "0.5"])
def test_rgba_from_hex_rejects_invalid_alpha(alpha):
    with pytest.raises(ValueError):
        candysole.rgba_from_hex("#ffffff", alpha)


def test_directory_from_uri():
    assert candysole.directory_from_uri(None) is None
    assert candysole.directory_from_uri("") is None
    assert candysole.directory_from_uri("https://example.com") is None
    assert candysole.directory_from_uri("file://remote/home/user") is None
    assert (
        candysole.directory_from_uri("file:///home/user/My%20Documents")
        == "/home/user/My Documents"
    )
    assert candysole.directory_from_uri("file://localhost/tmp") == "/tmp"


def test_parse_arguments_defaults():
    options = candysole.parse_arguments([])
    assert options.new_window is False
    assert options.working_directory is None
    assert options.command is None


def test_parse_arguments_options():
    options = candysole.parse_arguments(
        ["--new-window", "--working-directory", "/tmp"]
    )
    assert options.new_window is True
    assert options.working_directory == "/tmp"
    assert options.command is None


def test_parse_arguments_ignores_program_name():
    options = candysole.parse_arguments(["candysole", "--new-window"])
    assert options.new_window is True


def test_parse_arguments_command_consumes_remainder():
    options = candysole.parse_arguments(
        ["--working-directory", "/tmp", "-e", "printf", "%s", "--flag"]
    )
    assert options.working_directory == "/tmp"
    assert options.command == ["printf", "%s", "--flag"]


def test_parse_arguments_requires_command_after_e():
    with pytest.raises(SystemExit):
        candysole.parse_arguments(["-e"])


def test_exit_code_from_status():
    assert candysole.exit_code_from_status(0) == 0
    assert candysole.exit_code_from_status(None) == 0
    assert candysole.exit_code_from_status(256) == 1
    assert candysole.exit_code_from_status(127 << 8) == 127
    assert candysole.exit_code_from_status(15) == -15


def test_format_exit_message():
    assert (
        candysole.format_exit_message(1)
        == "[process exited with status 1]"
    )
    assert (
        candysole.format_exit_message(127)
        == "[process exited with status 127]"
    )
