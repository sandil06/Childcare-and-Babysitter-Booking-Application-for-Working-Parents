const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');

const DEFAULT_AGENCY_ACCOUNTS = [
  {
    name: 'Little Hands Agency',
    email: 'agency@littlehands.lk',
    role: 'agency',
    phone: '+94 11 234 5670',
    isEmailVerified: true,
  },
  {
    name: 'Chaminda Silva (Operations Admin)',
    email: 'admin@littlehands.lk',
    role: 'admin',
    phone: '+94 11 234 5678',
    isEmailVerified: true,
  },
  {
    name: 'Chief Compliance Officer',
    email: 'compliance@littlehands.lk',
    role: 'admin',
    phone: '+94 11 234 5679',
    isEmailVerified: true,
  },
];

async function seedAgencyUsers() {
  if (mongoose.connection.readyState !== 1) {
    return;
  }

  try {
    for (const acc of DEFAULT_AGENCY_ACCOUNTS) {
      const existing = await User.findOne({ email: acc.email.toLowerCase() });
      if (!existing && process.env.INITIAL_AGENCY_PASSWORD) {
        const passwordHash = await bcrypt.hash(process.env.INITIAL_AGENCY_PASSWORD, 12);
        await User.create({
          name: acc.name,
          email: acc.email.toLowerCase(),
          phone: acc.phone,
          passwordHash,
          role: acc.role,
          isEmailVerified: true,
        });
        console.log(`[Seed] Seeded administrative account: ${acc.email} (${acc.role})`);
      }
    }
  } catch (error) {
    console.error('[Seed] Error checking administrative users:', error.message);
  }
}

module.exports = seedAgencyUsers;
