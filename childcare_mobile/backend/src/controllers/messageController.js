const ApiResponse = require('../utils/ApiResponse');
function list(req, res) { return ApiResponse.success(res, []); }
function create(req, res) { return ApiResponse.success(res, req.body, 'Message sent', 201); }
module.exports = { list, create };
