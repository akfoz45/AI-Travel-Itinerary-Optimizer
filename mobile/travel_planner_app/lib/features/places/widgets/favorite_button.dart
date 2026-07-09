import 'package:flutter/material.dart';
import '../services/favorite_place_service.dart';

class FavoriteButton extends StatefulWidget {
  final int placeId;
  final bool initialIsFavorite;

  const FavoriteButton({
    super.key,
    required this.placeId,
    this.initialIsFavorite = false,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritePlaceService _favoriteService = FavoritePlaceService();
  late bool _isFavorite;
  bool _isLoading = false;
  bool _isInitialCheckDone = false; 

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
    _checkCurrentFavoriteStatus(); 
  }

  Future<void> _checkCurrentFavoriteStatus() async {
    try {
      final bool isFav = await _favoriteService.checkIfFavorite(widget.placeId);
      
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _isInitialCheckDone = true; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialCheckDone = true; 
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);

    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(widget.placeId);
      } else {
        await _favoriteService.addFavorite(widget.placeId);
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: _isFavorite ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialCheckDone) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 16, 
          height: 16, 
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }

    return IconButton(
      onPressed: _isLoading ? null : _toggleFavorite,
      icon: _isLoading 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : Colors.grey.shade400,
              size: 28,
            ),
    );
  }
}