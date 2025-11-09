import '../app_state.dart';

class CategoryMatcher {
  static final Map<CategoryType, List<String>> _keywords = {
    CategoryType.food: [
      'swiggy', 'zomato', 'uber eats', 'dominos', 'pizza', 'restaurant',
      'cafe', 'food', 'mcdonald', 'kfc', 'subway', 'starbucks', 'dunkin',
      'burger', 'biryani', 'kitchen', 'dine', 'eatery', 'bakery', 'chai'
    ],
    CategoryType.travel: [
      'uber', 'ola', 'rapido', 'irctc', 'makemytrip', 'goibibo', 'redbus',
      'flight', 'hotel', 'cab', 'taxi', 'petrol', 'fuel', 'parking',
      'toll', 'metro', 'bus', 'train', 'airline', 'airways'
    ],
    CategoryType.shopping: [
      'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'snapdeal',
      'shopping', 'mall', 'store', 'retail', 'fashion', 'clothing',
      'reliance', 'dmart', 'bigbasket', 'grofers', 'blinkit', 'zepto'
    ],
    CategoryType.luxuries: [
      'netflix', 'prime', 'hotstar', 'spotify', 'youtube', 'subscription',
      'gaming', 'entertainment', 'movie', 'cinema', 'pvr', 'inox',
      'playstation', 'xbox', 'steam', 'apple music', 'disney'
    ],
  };

  static CategoryType matchCategory(String merchant) {
    final merchantLower = merchant.toLowerCase();

    for (final entry in _keywords.entries) {
      if (entry.value.any((keyword) => merchantLower.contains(keyword))) {
        return entry.key;
      }
    }

    return CategoryType.other;
  }
}
