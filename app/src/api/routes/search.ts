import { Router } from 'express';
import SearchController from '../controllers/SearchController';

const router = Router();
const searchController = new SearchController();

/**
 * @swagger
 * tags:
 *   name: Search
 *   description: Global search functionality
 */

/**
 * @swagger
 * /api/search:
 *   get:
 *     summary: Global search across all entities
 *     tags: [Search]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: Search query
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [clients, vms, templates, logs]
 *         description: Limit search to specific entity type
 *     responses:
 *       200:
 *         description: Search results
 *       400:
 *         description: Invalid query parameters
 */
router.get('/', searchController.globalSearch.bind(searchController));

export default router;