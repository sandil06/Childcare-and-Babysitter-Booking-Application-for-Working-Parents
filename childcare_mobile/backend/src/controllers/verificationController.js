const ApiResponse = require('../utils/ApiResponse');
function list(req, res) { return ApiResponse.success(res, []); }
module.exports = { list };
