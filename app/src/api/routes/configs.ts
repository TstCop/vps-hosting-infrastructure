import { Router } from 'express';
import TemplateController from '../controllers/TemplateController';

const router = Router();
const templateController = new TemplateController();

// RF03.4: Script library
router.get('/scripts', templateController.getScripts.bind(templateController));

// RF03.5: Network configurations
router.get('/network-configs', templateController.getNetworkConfigs.bind(templateController));

// RF03.6: Resource profiles
router.get('/resource-profiles', templateController.getResourceProfiles.bind(templateController));

export default router;