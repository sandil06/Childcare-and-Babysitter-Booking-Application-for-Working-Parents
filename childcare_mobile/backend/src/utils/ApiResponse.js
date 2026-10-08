class ApiResponse {
  /**
   * Standard success response
   * @param {import('express').Response} res
   * @param {any} data
   * @param {string} [message='Success']
   * @param {number|object} [statusCodeOrMeta=200]
   * @param {object|null} [meta=null]
   */
  static success(res, data, message = 'Success', statusCodeOrMeta = 200, meta = null) {
    let statusCode = 200;
    let paginationMeta = meta;

    if (typeof statusCodeOrMeta === 'number') {
      statusCode = statusCodeOrMeta;
    } else if (statusCodeOrMeta && typeof statusCodeOrMeta === 'object') {
      paginationMeta = statusCodeOrMeta;
    }

    const payload = {
      success: true,
      message,
      data,
    };

    if (paginationMeta) {
      payload.meta = paginationMeta;
    }

    return res.status(statusCode).json(payload);
  }

  /**
   * Standard paginated response
   */
  static paginated(res, data, pagination = {}, message = 'Data retrieved successfully', statusCode = 200) {
    const total = Number(pagination.total !== undefined ? pagination.total : data.length);
    const limit = Number(pagination.limit || data.length || 1);
    const page = Number(pagination.page || 1);
    const totalPages = Math.ceil(total / limit) || 1;

    return res.status(statusCode).json({
      success: true,
      message,
      data,
      meta: {
        page,
        limit,
        total,
        totalPages,
      },
    });
  }

  /**
   * Standard 201 Created response
   */
  static created(res, data, message = 'Resource created successfully') {
    return this.success(res, data, message, 201);
  }

  /**
   * Direct error response
   */
  static error(res, message = 'An error occurred', statusCode = 400, details = null) {
    const payload = {
      success: false,
      message,
    };
    if (details) payload.details = details;
    return res.status(statusCode).json(payload);
  }
}

module.exports = ApiResponse;
