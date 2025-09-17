import { Router } from 'express';
import StatsController from '../controllers/StatsController';

const router = Router();
const statsController = new StatsController();

/**
 * @swagger
 * tags:
 *   name: Statistics
 *   description: System statistics and analytics
 */

/**
 * @swagger
 * /api/stats/overview:
 *   get:
 *     summary: Get system overview statistics
 *     tags: [Statistics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Overview statistics retrieved
 */
router.get('/overview', statsController.getOverview.bind(statsController));

export default router;