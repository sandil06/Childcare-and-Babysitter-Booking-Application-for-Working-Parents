# Nurture Backend

Node.js and Express API scaffold for the Nurture childcare booking app.

## Run locally

```bash
cd backend
npm install
npm run dev
```

The API runs on `http://localhost:4000` by default. Health check: `GET /api/v1/health`.

Copy `.env.example` to `.env` and configure MongoDB, JWT, Cloudinary, and Firebase credentials before enabling production integrations. The current app boots without MongoDB so the health route can be used during initial setup.

## Layout

- `src/controllers`: HTTP request handlers
- `src/services`: business logic and external integrations
- `src/models`: Mongoose model layer
- `src/routes`: API route composition
- `src/middleware`: cross-cutting request concerns
- `src/sockets`: real-time chat and tracking handlers
