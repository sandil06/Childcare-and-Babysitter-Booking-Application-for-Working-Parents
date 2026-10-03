const router = require('express').Router();
const availabilityController = require('../controllers/availabilityController');
const { validateUpdate } = require('../validators/availabilityValidator');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');

router.get('/', availabilityController.list);
router.patch(
  '/:id',
  authMiddleware,
  roleMiddleware(ROLES.BABYSITTER),
  validateUpdate,
  availabilityController.update
);
router.delete(
  '/:id',
  authMiddleware,
  roleMiddleware(ROLES.BABYSITTER),
  availabilityController.remove
);

module.exports = router;
