const ApiResponse = require('../utils/ApiResponse');
function dashboard(req, res) { return ApiResponse.success(res, { requests: [] }); }
module.exports = { dashboard };
