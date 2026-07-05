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

### Выплаты в КГ

В настройках Lemon Squeezy укажите **payout method** (банк / Payoneer / Wise — смотрите что доступно в вашем аккаунте).

### Pro-функции на backend

После первых оплат добавьте на Vercel:

- `OPENAI_API_KEY` — реальные загадки вместо demo  
- (опционально) webhook Lemon Squeezy для автоматической активации Pro

---

Внутренние скрипты: `MONETIZE.bat`, `scripts/setup-payments.ps1`, секреты в `.secrets.local` (gitignored).
