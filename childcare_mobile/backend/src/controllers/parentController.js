const mongoose = require('mongoose');
const ParentProfile = require('../models/ParentProfile');
const User = require('../models/User');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

const memoryParents = new Map();

async function getProfile(req, res, next) {
  try {
    const userId = req.user?.sub || req.user?.id;
    if (!userId) return next(new ApiError(401, 'Authentication required'));

    if (isDbConnected()) {
      let profile = await ParentProfile.findOne({ user: userId }).populate('user', 'name email phone avatar');
      if (!profile) {
        const user = await User.findById(userId);
        if (user) {
          profile = await ParentProfile.create({
            user: user._id,
            phone: user.phone || '',
            address: '',
            emergencyContact: '',
            children: [],
            isNicVerified: false,
          });
          await profile.populate('user', 'name email phone avatar');
        }
      }

      const responseData = {
        userId,
        name: profile?.user?.name || req.user?.name || 'Parent',
        email: profile?.user?.email || req.user?.email || '',
        phone: profile?.phone || profile?.user?.phone || '',
        avatar: profile?.avatar || profile?.profileImage || profile?.user?.avatar || profile?.user?.profileImage || null,
        profileImage: profile?.profileImage || profile?.avatar || profile?.user?.profileImage || profile?.user?.avatar || null,
        address: profile?.address || '',
        emergencyContact: profile?.emergencyContact || '',
        isNicVerified: profile?.isNicVerified || false,
        children: profile?.children || [],
        childrenCount: (profile?.children || []).length,
      };

      return ApiResponse.success(res, responseData, 'Parent profile retrieved');
    }

    // Memory store fallback
    let mem = memoryParents.get(userId.toString());
    if (!mem) {
      mem = {
        userId: userId.toString(),
        name: req.user?.name || 'Parent',
        email: req.user?.email || '',
        phone: req.user?.phone || '',
        avatar: null,
        profileImage: null,
        address: '',
        emergencyContact: '',
        isNicVerified: false,
        children: [],
        childrenCount: 0,
      };
      memoryParents.set(userId.toString(), mem);
    }
    return ApiResponse.success(res, mem, 'Parent profile retrieved');
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const userId = req.user?.sub || req.user?.id;
    if (!userId) return next(new ApiError(401, 'Authentication required'));

    const { name, phone, address, emergencyContact, children, avatar, profileImage } = req.body;
    const img = avatar || profileImage;

    let cleanPhone = phone;
    if (phone !== undefined && phone !== null && phone.toString().trim() !== '') {
      let digits = phone.toString().trim().replace(/\D/g, '');
      if (digits.startsWith('94') && digits.length === 11) {
        digits = digits.slice(2);
      }
      if (digits.length !== 10 && digits.length !== 9) {
        return next(new ApiError(400, 'Phone number must be exactly 10 digits'));
      }
      cleanPhone = phone.toString().trim();
    }

    let cleanEmergency = emergencyContact;
    if (emergencyContact !== undefined && emergencyContact !== null && emergencyContact.toString().trim() !== '') {
      let digits = emergencyContact.toString().trim().replace(/\D/g, '');
      if (digits.startsWith('94') && digits.length === 11) {
        digits = digits.slice(2);
      }
      if (digits.length !== 10 && digits.length !== 9) {
        return next(new ApiError(400, 'Emergency contact phone number must be exactly 10 digits'));
      }
      cleanEmergency = emergencyContact.toString().trim();
    }

    if (isDbConnected()) {
      if (name) {
        await User.findByIdAndUpdate(userId, { name });
      }
      if (cleanPhone !== undefined) {
        await User.findByIdAndUpdate(userId, { phone: cleanPhone });
      }
      if (img) {
        await User.findByIdAndUpdate(userId, { avatar: img, profileImage: img });
      }
      const updateData = {};
      if (cleanPhone !== undefined) updateData.phone = cleanPhone;
      if (address !== undefined) updateData.address = address;
      if (cleanEmergency !== undefined) updateData.emergencyContact = cleanEmergency;
      if (children !== undefined) updateData.children = children;
      if (img) {
        updateData.avatar = img;
        updateData.profileImage = img;
      }

      const profile = await ParentProfile.findOneAndUpdate(
        { user: userId },
        { $set: updateData },
        { new: true, upsert: true }
      ).populate('user', 'name email phone avatar profileImage');

      const responseData = {
        userId,
        name: profile?.user?.name || name,
        email: profile?.user?.email || '',
        phone: profile?.phone || phone || '',
        avatar: profile?.avatar || profile?.profileImage || profile?.user?.avatar || profile?.user?.profileImage || img || null,
        profileImage: profile?.profileImage || profile?.avatar || profile?.user?.profileImage || profile?.user?.avatar || img || null,
        address: profile?.address || address || '',
        emergencyContact: profile?.emergencyContact || emergencyContact || '',
        isNicVerified: profile?.isNicVerified || false,
        children: profile?.children || [],
        childrenCount: (profile?.children || []).length,
      };

      return ApiResponse.success(res, responseData, 'Parent profile updated successfully');
    }

    const existing = memoryParents.get(userId.toString()) || {};
    const updated = { ...existing, ...req.body };
    if (img) {
      updated.avatar = img;
      updated.profileImage = img;
    }
    memoryParents.set(userId.toString(), updated);
    return ApiResponse.success(res, updated, 'Parent profile updated successfully');
  } catch (err) {
    next(err);
  }
}

function setMemoryParentProfile(userId, data) {
  memoryParents.set(userId.toString(), {
    userId: userId.toString(),
    name: data.name || 'Parent',
    email: data.email || '',
    phone: data.phone || '',
    address: data.address || '',
    emergencyContact: data.emergencyContact || '',
    isNicVerified: data.isNicVerified || false,
    children: data.children || [],
    childrenCount: (data.children || []).length,
  });
}

module.exports = { getProfile, updateProfile, setMemoryParentProfile, memoryParents };
