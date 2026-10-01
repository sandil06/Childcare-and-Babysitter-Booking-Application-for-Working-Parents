const ApiResponse = require('../utils/ApiResponse');
function list(req, res) { return ApiResponse.success(res, []); }
function create(req, res) { return ApiResponse.success(res, req.body, 'Booking created', 201); }
module.exports = { list, create };
