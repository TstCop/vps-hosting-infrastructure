import express, { Request, Response, NextFunction } from 'express';
import bodyParser from 'body-parser';
import clientRoutes from './routes/clients';
import vmRoutes from './routes/vms';
import { authMiddleware } from './middleware/auth';

const app = express();

// Middleware
app.use(bodyParser.json());

// Only use auth middleware if not in test environment
if (process.env.NODE_ENV !== 'test') {
    app.use(authMiddleware);
}

// Routes
app.use('/api/clients', clientRoutes);
app.use('/api/vms', vmRoutes);

// Error handling
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err.stack);
    res.status(500).send('Something broke!');
});

export default app;