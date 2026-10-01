const router = require('express').Router();
const { list } = require('../controllers/babysitterController');
router.get('/', list);
module.exports = router;
