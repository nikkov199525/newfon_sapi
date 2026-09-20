# Newfon SAPI

sapi- версия именно newfon.


В комплекте идёт конфигуратор, в котором можно изменить  частоту дискретизации, интерполяцию, ускорение и много всего еще.


## Сборка

Нужны:

- [LLVM-MinGW](https://github.com/mstorsjo/llvm-mingw) — в `PATH` или в переменной `LLVM_MINGW`;
- [CMake](https://cmake.org/) 3.24 или новее;
- [PureBasic](https://www.purebasic.com/) — для конфигуратора;
- [Inno Setup 6](https://jrsoftware.org/isinfo.php) — для установщика;
- Python 3 — для проверки конфигуратора.

```bash
git clone --recursive https://github.com/nikkov199525/newfon_sapi
```

Дальше одна команда собирает обе разрядности, прогоняет тесты и делает
установщик в `build\x64\installer`:

```bash
build_release.cmd
```
