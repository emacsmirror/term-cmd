# ruff: noqa: S101

import pytest


class TestExample:
    def test_example1(self) -> None:
        assert True

    @pytest.mark.slow
    def test_example2(self) -> None:
        assert True
