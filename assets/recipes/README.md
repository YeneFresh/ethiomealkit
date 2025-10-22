# Recipe Images

## Placeholder Images

Place recipe images in this directory with the following naming convention:
- `injera-beef-stew.jpg`
- `doro-wat.jpg`
- `kitfo.jpg`
- `shiro-wat.jpg`
- `tibs.jpg`

## Image Requirements
- Format: JPG or PNG
- Recommended size: 800x600px
- Max file size: 500KB
- Quality: 80-90%

## Placeholder Usage

Until real images are added, the app will:
1. Check for local asset first
2. Try image_url from database
3. Fall back to icon placeholder

## Adding New Images

1. Add image file to `assets/recipes/`
2. Update recipe in database with matching slug
3. Image will auto-load via `image_url` field

Example:
```dart
Image.asset(
  'assets/recipes/${recipe.slug}.jpg',
  errorBuilder: (_, __, ___) => Icon(Icons.restaurant),
)
```





