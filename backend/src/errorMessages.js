const errorMessages = {
  SERVER_ERROR: 'An unexpected server error occurred. Please try again later.',
  INVESTOR_NOT_FOUND: 'Investor not found. Please check the ID and try again.',
  INVESTOR_EXISTS: 'An investor with this email already exists.',
  INVALID_INPUT: 'Invalid input. Please check the data and try again.',
  AUTH_REQUIRED: 'Authentication required. Please log in.',
  INVALID_CREDENTIALS: 'Invalid email or password.',
  MISSING_FIELDS: 'Required fields are missing. Please fill all required fields.',
  FILE_UPLOAD_ERROR: 'There was an error processing the uploaded file.',
  NO_FIELDS_TO_UPDATE: 'No fields to update.',
  TRANSACTION_SUBMIT_SUCCESS: 'Transaction submitted for approval.',
  TRANSACTION_SUBMIT_FAIL: 'Failed to submit transaction. Please try again.',
  DELETE_SUCCESS: 'Investor deleted successfully.',
  DELETE_FAIL: 'Failed to delete. Please try again.',
  UPDATE_FAIL: 'Failed to update. Please try again.',
};

export default errorMessages;
