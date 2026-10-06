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
app.use(cors({
	origin: (origin, callback) => {
		if (env.isAllowedClientOrigin(origin)) return callback(null, true);
		return callback(null, false);
	},
	allowedHeaders: ['Content-Type', 'Accept', 'Authorization'],
	methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
}));
app.use(
	express.json({
		limit: '1mb',
		verify: (req, res, buf) => {
			req.rawBody = buf;
		},
	})
);
app.use(express.urlencoded({ extended: true }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use(apiRateLimit);
app.use('/uploads', express.static(path.resolve('uploads')));
app.use('/api/v1', routes);
app.use(notFoundMiddleware);
app.use(errorMiddleware);

module.exports = app;
