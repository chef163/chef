# 👟 Кроссовки: Ломай Стену +1

Готовая Roblox-игра в стиле «+1 каждую секунду»: сила растёт сама, ты ломаешь мемные стены, получаешь деньги
и покупаешь всё более дорогие (пародийные) брендовые кроссовки, которые ускоряют рост силы.

## Как играть

1. Каждую секунду получаешь **+1 ⚡ силы** (с кроссовками и ребёртами — больше).
2. Подходишь к стене и кликаешь (или жмёшь **👊 УДАР** / клавишу **F**). Урон = твоя сила.
3. За сломанную стену дают 💰 деньги, и открывается путь к следующей: 10 стен, HP растёт от 25 до 100M.
4. На деньги покупаешь 👟 кроссовки. Каждую пару можно брать много раз, и **каждая покупка дороже предыдущей** (×1.55).
   Лучшая пара появляется у персонажа на ногах.
5. Финальная стена даёт 🏆 победу и телепорт на старт.
6. 🔁 Ребёрт сбрасывает силу, деньги и кроссы, но навсегда добавляет +50% к приросту.

Мемы: стены «BRUH», «Сигма», «Огайо», «Скибиди», «Ризз», «Амогус», «Чилл Гай», «Гигачад»; вылетающие надписи
(SHEESH, +1000 AURA, GG EZ…), звуки на удар, разрушение, покупку и победу, крутящиеся кроссы на витринах, обломки и тряска камеры.

## Структура

```
default.project.json          — проект Rojo
src/shared/Config.luau        — ВСЕ настройки: баланс, стены, кроссовки, звуки, мемы
src/shared/Format.luau        — 1500 → 1.5K
src/shared/ShoeBuilder.luau   — моделька кроссовка из деталей
src/server/MapBuilder.luau    — строит карту кодом
src/server/GameServer.server.luau — логика, магазин, ребёрты, сохранения
src/client/Client.client.luau — интерфейс, звуки, эффекты
```

## Установка

### Вариант А — Rojo (удобнее)
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

## Идеи для монетизации (Game Pass)
- x2 сила навсегда, авто-удар VIP, x2 деньги
- Эксклюзивные кроссовки (например, «Золотые Скибиди-Кроссы»)
- Developer Product «+10 минут силы мгновенно»
