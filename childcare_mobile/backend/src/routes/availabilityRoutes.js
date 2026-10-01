const router = require('express').Router();
const { list } = require('../controllers/availabilityController');
router.get('/', list);
module.exports = router;
