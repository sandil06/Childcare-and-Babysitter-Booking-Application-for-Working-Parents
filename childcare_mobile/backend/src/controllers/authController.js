const bcrypt = require('bcryptjs');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');
const generateToken = require('../utils/generateToken');
const ROLES = require('../constants/roles');

async function register(req, res) {
  const { name, email, password, role = ROLES.PARENT } = req.body;
  const passwordHash = await bcrypt.hash(password, 12);
  const user = { id: `local-${Date.now()}`, name, email, role, passwordHash };
  return ApiResponse.success(res, { user: { id: user.id, name, email, role }, token: generateToken({ sub: user.id, role }) }, 'Registered', 201);
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return next(new ApiError(400, 'Email and password are required'));
    const user = { id: 'local-user', email, role: ROLES.PARENT, passwordHash: await bcrypt.hash(password, 12) };
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return next(new ApiError(401, 'Invalid credentials'));
    return ApiResponse.success(res, { user: { id: user.id, email: user.email, role: user.role }, token: generateToken({ sub: user.id, role: user.role }) });
  } catch (error) { next(error); }
}

function me(req, res) { return ApiResponse.success(res, { user: req.user }); }

module.exports = { register, login, me };
