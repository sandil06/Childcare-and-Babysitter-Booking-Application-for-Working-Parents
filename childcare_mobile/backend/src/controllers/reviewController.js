const ApiResponse = require('../utils/ApiResponse');
function create(req, res) { return ApiResponse.success(res, req.body, 'Review created', 201); }
module.exports = { create };
