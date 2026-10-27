# Пользовательская конфигурация

Снимок настроек действующей установки от 27 октября 2026 г. Эти файлы находятся вне каталога Quickshell и сохраняются здесь вместе с исходниками Shell.

- `caelestia/`: настройки Shell, переопределения и дополнительные хоткеи Hyprland.
- `hypr/hyprland/input.lua`: настройки ввода и `Alt + Shift`, переключающий все клавиатуры на один номер раскладки. Требуются `jq` и `xargs`.
- `voxtype/config.toml`: локальное распознавание русского через Whisper; `Super + Shift + D` включает/выключает запись, `Super + Shift + Escape` отменяет её.
- `systemd/user/voxtype.service`: автозапуск Voxtype в графическом сеансе.

Диктовка использует выбранный системный микрофон, в том числе микрофон Bluetooth-гарнитуры. `pause_media = true` ставит на паузу только проигрыватели, которые уже воспроизводили звук, и возобновляет их сразу после остановки или отмены записи. Проигрыватели, которые были на паузе до записи, не запускаются. Это работает через MPRIS, в том числе для Spotify и поддерживающих этот интерфейс браузеров.

Voxtype 1.1.1, бинарный файл `~/.local/bin/voxtype` и модель `~/.local/share/voxtype/models/ggml-large-v3-turbo-q5_0.bin` (~574 МБ) устанавливаются отдельно и в Git не включены. Источники: [Voxtype](https://github.com/peteonrails/voxtype/releases/tag/v1.1.1), [модель Whisper](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-large-v3-turbo-q5_0.bin). Нужны рабочие PipeWire-Pulse, ALSA PulseAudio plugin, `wl-copy`, `notify-send` и Vulkan.

Это снимок конкретного ноутбука: в путях модели и службы используется `/home/kirill`. На другом компьютере эти пути нужно заменить.

Для восстановления настроек на текущем ноутбуке после установки зависимостей и модели, из корня репозитория:

Если была установлена предыдущая версия снимка с привязкой к встроенному микрофону, предварительно удалите `~/.config/systemd/user/voxtype.service.d/microphone.conf`. В текущей версии этот override не используется.

```sh
cp -a extras/local-config/caelestia extras/local-config/voxtype extras/local-config/hypr ~/.config/
cp -a extras/local-config/systemd/user/. ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now voxtype
systemctl --user restart voxtype
hyprctl reload
```

Caelestia dotfiles должны загружать `~/.config/caelestia/hypr-user.lua` и `hypr-vars.lua`. После изменения QML перезапустите Shell: в этом снимке автоматическая перезагрузка файлов отключена.

Проверка исправления раскладок в действующем Hyprland: `python3 tests/test_keyboard_layout.py` из корня репозитория. Проверка временно переключает EN/RU/UA, проверяет индикатор и синхронизацию устройств, затем восстанавливает исходный номер раскладки основной клавиатуры.

Проверено на действующей установке: активные проигрыватели ставятся на паузу и возобновляются после записи, ранее приостановленные не запускаются; индикатор виден дольше штатного тайм-аута и при повторном запуске диктовки. Сборка C++ плагина из исходников при сохранении снимка не выполнялась.
