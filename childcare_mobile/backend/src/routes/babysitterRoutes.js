const router = require('express').Router();
const babysitterController = require('../controllers/babysitterController');
const { validateRegister, validateUpdate } = require('../validators/babysitterValidator');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');

// Public routes
router.post('/register', validateRegister, babysitterController.register);
router.get('/', babysitterController.list);

// Authenticated babysitter routes
router.get('/me', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.getMe);
router.patch('/me', authMiddleware, roleMiddleware(ROLES.BABYSITTER), validateUpdate, babysitterController.updateMe);
router.get('/me/dashboard', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.getDashboard);

// Details by ID
router.get('/:id', babysitterController.getById);

module.exports = router;
