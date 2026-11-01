import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../providers/journey_provider.dart';
import '../services/geocoding_service.dart';
import '../services/storage_service.dart';
import '../utils/colors.dart';
import '../widgets/glass_card.dart';

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({super.key});

  @override
  State<SearchDestinationScreen> createState() => _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = false;
  String? _errorMessage;
  List<Destination> _searchResults = [];
  List<Destination> _recentDestinations = [];
  List<Destination> _favoriteDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  void _loadRecents() {
    final storage = context.read<StorageService>();
    setState(() {
      _recentDestinations = storage.getRecentDestinations();
      _favoriteDestinations = storage.getFavoriteDestinations();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await GeocodingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          if (results.isEmpty) {
            _errorMessage = 'No destinations found for "$query". Try a city, station, or landmark name.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to search destinations. Please check your internet connection.';
        });
      }
    }
  }

  void _selectDestination(Destination destination) {
    context.read<JourneyProvider>().setDestination(destination);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Destination'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search city, train station, bus stop...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryAccent),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),

            if (_errorMessage != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  backgroundColor: AppColors.cardBackground,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Search Results or Recents
            Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final dest = _searchResults[index];
                        return _buildDestinationTile(dest, isRecent: false);
                      },
                    )
                  : _buildRecentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentsList() {
    if (_recentDestinations.isEmpty && _favoriteDestinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 64,
              color: AppColors.secondarySurface,
            ),
            const SizedBox(height: 16),
            const Text(
              'Search for your travel stop',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Train station, airport, bus terminal, or town',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_favoriteDestinations.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'Saved Favorites (Offline)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ..._favoriteDestinations.map((dest) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDestinationTile(dest, isRecent: false, isFavorite: true),
              )),
          const SizedBox(height: 14),
        ],
        if (_recentDestinations.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Recent Destinations (Offline)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ..._recentDestinations.map((dest) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDestinationTile(dest, isRecent: true),
              )),
        ],
      ],
    );
  }

  Widget _buildDestinationTile(Destination dest, {required bool isRecent, bool isFavorite = false}) {
    final storage = context.read<StorageService>();
    final isFav = isFavorite || storage.isFavorite(dest);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _selectDestination(dest),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFav
                  ? Colors.amber.withValues(alpha: 0.16)
                  : (isRecent
                      ? AppColors.secondarySurface
                      : AppColors.primaryAccent.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFav
                  ? Icons.star_rounded
                  : (isRecent ? Icons.history_rounded : Icons.place_rounded),
              color: isFav
                  ? Colors.amber
                  : (isRecent ? AppColors.textSecondary : AppColors.primaryAccent),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dest.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dest.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFav ? Colors.amber : const Color(0xFF5A708A),
              size: 20,
            ),
            tooltip: isFav ? 'Remove Favorite' : 'Save as Favorite',
            onPressed: () async {
              await storage.toggleFavoriteDestination(dest);
              _loadRecents();
            },
          ),
        ],
      ),
    );
  }
}
