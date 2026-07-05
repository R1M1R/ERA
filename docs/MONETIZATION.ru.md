# ERA — монетизация (только для владельца)

> Не дублируется в README. Публичный README — для пользователей приложения.

## Кыргызстан: Stripe недоступен

Stripe **не поддерживает** регистрацию продавцов из Кыргызстана.

Используйте **Merchant of Record** — они принимают платежи от клиентов по всему миру и переводят вам выплаты:

| Платформа | Комиссия | Подписки | Для ERA |
|-----------|----------|----------|---------|
| **[Lemon Squeezy](https://www.lemonsqueezy.com)** (рекомендуется) | 5% + $0.50 | ✅ | SaaS / подписка $12/мес |
| **[Paddle](https://www.paddle.com)** | 5% + $0.50 | ✅ | Если масштабируетесь |
| **[Gumroad](https://gumroad.com)** | 10% + $0.50 | ✅ | Проще, но дороже |

### Пошагово: Lemon Squeezy (Кыргызстан)

1. Регистрация: https://www.lemonsqueezy.com  
2. **Store** → **Products** → **New product**  
   - Name: `ERA Pro`  
   - Price: `$12` / month (subscription)  
3. Скопируйте **Checkout URL** (вида `https://….lemonsqueezy.com/checkout/buy/...`)  
4. Запустите **`MONETIZE.bat`** и вставьте URL  
   - или вручную в Vercel: env `VITE_PRO_PAYMENT_LINK` = ваш checkout URL  
5. Из корня репо:
   ```powershell
   npx vercel env add VITE_PRO_PAYMENT_LINK production
   npx vercel --prod
   ```
6. На сайте кнопка **Upgrade to Pro** откроет оплату.

### Webhook — автоматическая активация Pro

После оплаты ERA создаёт API-ключ (`era_pro_…`). Пользователь получает его на сайте в секции **Pro** по email с checkout.

1. Lemon Squeezy → **Settings** → **Webhooks** → **+**  
2. **Callback URL:**
   ```
   https://frontend-flax-two-11q4abvz2o.vercel.app/webhooks/lemonsqueezy
   ```
3. События: `subscription_created`, `subscription_updated`, `subscription_cancelled`, `subscription_expired`, `subscription_payment_success`  
4. Скопируйте **Signing secret**  
5. Добавьте на Vercel:
   ```powershell
   npx vercel env add LEMONSQUEEZY_WEBHOOK_SECRET production
   npx vercel --prod
   ```

Или запустите **`scripts/setup-lemonsqueezy-webhook.ps1`**.

### OpenAI для Pro-пользователей

Бесплатные пользователи всегда получают **демо-загадки**. Pro с активным ключом получает **реальный GPT**, если на сервере задан ключ:

```powershell
npx vercel env add OPENAI_API_KEY production
npx vercel --prod
```

`ERA_DEMO_MODE=true` на Vercel остаётся — это нормально: демо только для free, Pro обходит через API-ключ.

### Выплаты в КГ

В настройках Lemon Squeezy укажите **payout method** (банк / Payoneer / Wise — смотрите что доступно в вашем аккаунте).

### Как пользователь активирует Pro

1. Оплата на Lemon Squeezy  
2. На сайте → секция **Pro** → ввод email с оплаты → **Получить Pro ключ**  
3. Ключ сохраняется в браузере; генерация отправляет заголовок `X-ERA-Pro-Key`  
4. В шапке появляется бейдж **Pro active**

---

Внутренние скрипты: `MONETIZE.bat`, `scripts/setup-payments.ps1`, `scripts/setup-lemonsqueezy-webhook.ps1`, секреты в `.secrets.local` (gitignored).
