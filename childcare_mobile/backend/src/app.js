const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('node:path');
const env = require('./config/env');
const apiRateLimit = require('./middleware/rateLimitMiddleware');
const routes = require('./routes');
const { notFoundMiddleware, errorMiddleware } = require('./middleware/errorMiddleware');

const app = express();
app.use(helmet());
app.use(cors({ origin: env.clientOrigin === '*' ? true : env.clientOrigin }));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use(apiRateLimit);
app.use('/uploads', express.static(path.resolve('uploads')));
app.use('/api/v1', routes);
app.use(notFoundMiddleware);
app.use(errorMiddleware);

module.exports = app;
