import express from 'express';
import bodyParser from 'body-parser';
import clientRoutes from './routes/clients';
import vmRoutes from './routes/vms';
import { authMiddleware } from './middleware/auth';
import { validationMiddleware } from './middleware/validation';

const app = express();

// Middleware
app.use(bodyParser.json());
app.use(authMiddleware);
app.use(validationMiddleware);

// Routes
app.use('/api/clients', clientRoutes);
app.use('/api/vms', vmRoutes);

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send('Something broke!');
});

export default app;