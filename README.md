# 👟 Кроссовки: Ломай Стену +1

Готовая Roblox-игра в стиле «+1 каждую секунду»: сила растёт сама, ты ломаешь мемные стены, получаешь деньги,
покупаешь всё более дорогие (пародийные) брендовые кроссовки и мемных питомцев.

## 🚀 Как запустить (самый простой способ)

1. Установи **Roblox Studio**: зайди на https://create.roblox.com, нажми **Start Creating** / **Download Studio** и войди в свой Roblox-аккаунт.
2. Скачай файл **`SneakerWall.rbxlx`** из этого репозитория (на GitHub: открой файл → кнопка **Download raw file**).
3. Открой его двойным кликом (или в Studio: **File → Open from File…** → выбери `SneakerWall.rbxlx`).
4. Нажми зелёную кнопку **▶ Play** сверху (или **F5**). Карта строится сама при запуске, поэтому в редакторе до Play мир пустой — так и должно быть.
5. Чтобы выйти из теста: красная кнопка **■ Stop** (Shift+F5).

### Как выложить игру, чтобы в неё могли зайти другие
1. В Studio: **File → Publish to Roblox** → придумай название → **Create**.
2. **Home → Game Settings → Security** → включи **Enable Studio Access to API Services** → Save (нужно для сохранений и таблиц лидеров).
3. На https://create.roblox.com/dashboard/creations открой игру → **Configure** / **Permissions** → поставь **Public**.
4. Всё, ссылку на игру можно кидать друзьям.

### Как менять игру
Все цифры, названия, цвета и звуки лежат в одном скрипте: в Studio открой **Explorer → ReplicatedStorage → Shared → Config**
(двойной клик) и меняй. После изменений снова жми **Play**, а для обновления опубликованной игры — **File → Publish to Roblox**.

## Как играть

1. Каждую секунду получаешь **+1 ⚡ силы** (с кроссовками и ребёртами — больше).
2. Подходишь к стене и кликаешь (или жмёшь **👊 УДАР** / клавишу **F**). Урон = твоя сила.
3. За сломанную стену дают 💰 деньги, и открывается путь к следующей. 15 стен в 2 зонах: «Мемы» и «Мир Мемов» (Доге, Шлёпа, Хомяк, Пепе, Шрек), HP растёт от 25 до 1T.
4. На деньги покупаешь 👟 кроссовки. Каждую пару можно брать много раз, и **каждая покупка дороже предыдущей** (×1.55).
   Лучшая пара появляется у персонажа на ногах.
5. Финальная стена даёт 🏆 победу и телепорт на старт.
6. 🐾 **Питомцы** (Доге, Шлёпа, Амогус, Хомяк, Скибиди Туалет, Чилл Гай, Пепе, Гигачад) летают за тобой и умножают прирост силы (до x20). Покупаются один раз и остаются после ребёрта.
7. 🔁 Ребёрт сбрасывает силу, деньги и кроссы, но навсегда добавляет +50% к приросту.
8. 🏆 За спавном стоят две глобальные таблицы лидеров: **Топ побед** и **Топ силы**.
9. 💎 Game Pass'ы: x2 Сила, x2 Деньги, Турбо авто-удар.

Мемы: стены «BRUH», «Сигма», «Огайо», «Скибиди», «Ризз», «Амогус», «Чилл Гай», «Гигачад»; вылетающие надписи
(SHEESH, +1000 AURA, GG EZ…), звуки на удар, разрушение, покупку и победу, крутящиеся кроссы на витринах, обломки и тряска камеры.

## Структура

```
default.project.json          — проект Rojo
src/shared/Config.luau        — ВСЕ настройки: баланс, стены, кроссовки, звуки, мемы
src/shared/Format.luau        — 1500 → 1.5K
src/shared/ShoeBuilder.luau   — моделька кроссовка из деталей
src/shared/PetBuilder.luau    — моделька питомца из деталей
SneakerWall.rbxlx             — готовый файл игры (собран из src/ командой `rojo build -o SneakerWall.rbxlx`)
src/server/MapBuilder.luau    — строит карту кодом
src/server/GameServer.server.luau — логика, магазин, ребёрты, сохранения
src/client/Client.client.luau — интерфейс, звуки, эффекты
```

## Установка для разработчиков

### Вариант А — Rojo
1. Поставь [Rojo](https://rojo.space) и плагин Rojo для Studio.
2. В папке проекта: `rojo serve`.
3. В Studio создай пустой Baseplate → плагин Rojo → **Connect** → жми ▶ Play.

### Вариант Б — вручную в Studio
| Что создать | Где | Имя | Вставить код из |
|---|---|---|---|
| Folder | ReplicatedStorage | `Shared` | — |
| ModuleScript | ReplicatedStorage → Shared | `Config` | `src/shared/Config.luau` |
| ModuleScript | ReplicatedStorage → Shared | `Format` | `src/shared/Format.luau` |
| ModuleScript | ReplicatedStorage → Shared | `ShoeBuilder` | `src/shared/ShoeBuilder.luau` |
| ModuleScript | ReplicatedStorage → Shared | `PetBuilder` | `src/shared/PetBuilder.luau` |
| Folder | ServerScriptService | `Server` | — |
| ModuleScript | ServerScriptService → Server | `MapBuilder` | `src/server/MapBuilder.luau` |
| Script | ServerScriptService → Server | `GameServer` | `src/server/GameServer.server.luau` |
| LocalScript | StarterPlayer → StarterPlayerScripts | `Client` | `src/client/Client.client.luau` |

Карту руками строить не нужно: она появится сама при запуске.

### Сохранения
Чтобы прогресс сохранялся: **Game Settings → Security → Enable Studio Access to API Services** (игра должна быть опубликована).

## 🔊 Мемные звуки

Сейчас стоят встроенные звуки Roblox, чтобы всё работало сразу. Замени их на мемы:
1. Studio → **Toolbox → Audio** (Creator Store), ищи: `vine boom`, `bruh`, `cha ching`, `airhorn`, `sad violin`, `among us`, `sheesh`.
2. Проверь, что звук играет (чужие длинные аудио часто закрыты). Короткие звуки и аудио от Roblox обычно доступны. Можно загрузить свои через Creator Hub.
3. Скопируй ID и впиши в `Config.Sounds`, например `WallBreak = { "rbxassetid://1234567890" }`.
   В списке может быть несколько ID: будет играть случайный. `Memes` — случайный звук после каждой сломанной стены, `Music` — фоновая музыка.

## Баланс
Все цифры лежат в `src/shared/Config.luau`: HP и награды стен, цены и бонусы кроссовок, `PRICE_GROWTH` (насколько дорожают),
`REBIRTH_BONUS`, дальность удара, скорость авто-удара. Новую стену или кроссовок добавляешь одной строкой в таблицу.

## ⚠️ Про бренды
Названия пародийные (Air Farce 1, Jordon 4, Yeezus Boost…). Настоящие логотипы и названия брендов в Roblox
могут стать причиной жалобы правообладателя и удаления игры, так что лучше оставить пародии.

## 💎 Как включить Game Pass'ы
1. Опубликуй игру (см. выше).
2. https://create.roblox.com/dashboard/creations → твоя игра → **Monetization → Passes → Create a Pass**: загрузи картинку, название (например «x2 Сила»), нажми Create.
3. Открой пасс → **Sales** → включи продажу и поставь цену в Robux.
4. Скопируй **ID** пасса (число в ссылке) и впиши в `Config.GamePasses` вместо `0` у нужного пасса.
5. Опубликуй игру заново. Пока стоит `0`, кнопка покупки просто подсказывает, что пасс не настроен.
