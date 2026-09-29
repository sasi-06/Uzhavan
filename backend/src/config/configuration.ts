export default () => ({
  port: parseInt(process.env.API_PORT ?? '3000', 10),
  jwt: {
    secret: process.env.JWT_SECRET ?? 'dev-secret',
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },
  otp: {
    expiresSeconds: parseInt(process.env.OTP_EXPIRES_SECONDS ?? '300', 10),
  },
  postgres: {
    host: process.env.POSTGRES_HOST ?? 'localhost',
    port: parseInt(process.env.POSTGRES_PORT ?? '5432', 10),
    username: process.env.POSTGRES_USER ?? 'uzhavan',
    password: process.env.POSTGRES_PASSWORD ?? 'uzhavan_dev',
    database: process.env.POSTGRES_DB ?? 'uzhavan',
  },
  redis: {
    host: process.env.REDIS_HOST ?? 'localhost',
    port: parseInt(process.env.REDIS_PORT ?? '6379', 10),
  },
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID ?? '',
    keySecret: process.env.RAZORPAY_KEY_SECRET ?? '',
  },
  commission: {
    ratePercent: parseFloat(process.env.COMMISSION_RATE ?? '10'),
  },
});
