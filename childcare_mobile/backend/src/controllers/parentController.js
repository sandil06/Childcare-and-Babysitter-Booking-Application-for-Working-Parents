const ApiResponse = require('../utils/ApiResponse');
function getProfile(req, res) { return ApiResponse.success(res, { userId: req.user?.sub || null }); }
module.exports = { getProfile };
