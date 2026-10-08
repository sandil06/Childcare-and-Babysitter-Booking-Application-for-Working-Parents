const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');

const BabysitterProfile = require('../models/BabysitterProfile');

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

  const defaultPassword = process.env.INITIAL_AGENCY_PASSWORD || 'AdminSecure123!';

  try {
    for (const acc of DEFAULT_AGENCY_ACCOUNTS) {
      const emailLower = acc.email.toLowerCase();
      let existing = await User.findOne({ email: emailLower });
      if (!existing) {
        const passwordHash = await bcrypt.hash(defaultPassword, 12);
        existing = await User.create({
          name: acc.name,
          email: emailLower,
          phone: acc.phone,
          passwordHash,
          role: acc.role,
          isEmailVerified: true,
        });
        console.log(`[Seed] Seeded administrative account: ${acc.email} (${acc.role})`);
      } else {
        let changed = false;
        if (existing.role !== acc.role) {
          existing.role = acc.role;
          changed = true;
        }
        if (!existing.isEmailVerified) {
          existing.isEmailVerified = true;
          changed = true;
        }
        const matchesPassword = await bcrypt.compare(defaultPassword, existing.passwordHash || '');
        if (!matchesPassword) {
          existing.passwordHash = await bcrypt.hash(defaultPassword, 12);
          changed = true;
        }
        if (changed) {
          await existing.save();
          console.log(`[Seed] Restored administrative account role/credentials: ${acc.email} (${acc.role})`);
        }
      }

      // Ensure no administrative account ever has a BabysitterProfile attached
      try {
        await BabysitterProfile.deleteMany({ user: existing._id });
      } catch (_) {}
    }
  } catch (error) {
    console.error('[Seed] Error checking administrative users:', error.message);
  }
}

module.exports = seedAgencyUsers;
