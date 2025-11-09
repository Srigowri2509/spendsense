class SmsSenders {
  static const List<String> paymentApps = [
    'GPAY',      // Google Pay
    'PHONEPE',   // PhonePe
    'PAYTM',     // Paytm
    'AMAZONPAY', // Amazon Pay
    'MOBIKWIK',  // MobiKwik
    'FREECHARGE',// FreeCharge
    'BHIM',      // BHIM UPI
  ];

  static const List<String> banks = [
    'HDFCBK',    // HDFC Bank
    'ICICIB',    // ICICI Bank
    'SBIIN',     // State Bank of India
    'AXISBK',    // Axis Bank
    'KOTAKBK',   // Kotak Bank
    'PNBSMS',    // Punjab National Bank
    'BOISMS',    // Bank of India
    'CBSSBI',    // SBI
    'IDFCBK',    // IDFC First Bank
    'YESBNK',    // Yes Bank
    'INDBNK',    // IndusInd Bank
  ];

  static List<String> getAllSenders() {
    return [...paymentApps, ...banks];
  }
}
