import { Router } from 'express';
import TemplateController from '../controllers/TemplateController';

const router = Router();
const templateController = new TemplateController();

// RF03.1: Create custom template
router.post('/', templateController.createTemplate.bind(templateController));

// Get all templates with filtering
router.get('/', templateController.getTemplates.bind(templateController));

// Get specific template
router.get('/:id', templateController.getTemplate.bind(templateController));

// RF03.2: Edit template
router.put('/:id', templateController.updateTemplate.bind(templateController));

// Delete template
router.delete('/:id', templateController.deleteTemplate.bind(templateController));

// RF03.3: Template versions
router.get('/:id/versions', templateController.getTemplateVersions.bind(templateController));

export default router;