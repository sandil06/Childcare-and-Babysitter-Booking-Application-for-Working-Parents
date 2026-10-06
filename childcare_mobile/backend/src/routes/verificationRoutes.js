const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');
const verificationController = require('../controllers/verificationController');

const requireAgency = roleMiddleware(ROLES.AGENCY, ROLES.ADMIN);

router.get('/', auth, requireAgency, verificationController.list);
router.get('/:id', auth, requireAgency, verificationController.getById);

module.exports = router;
