import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/services/search_service.dart';
import 'package:flutter_pos_offline/utils/constants.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({
    super.key,
    required this.hintText,
    required this.onSearch,
    this.onSuggestionTap,
    this.showSuggestions = true,
    this.showRecentSearches = true,
  });

  final String hintText;
  final ValueChanged<String> onSearch;
  final ValueChanged<String>? onSuggestionTap;
  final bool showSuggestions;
  final bool showRecentSearches;

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchService _searchService = SearchService();

  Timer? _debounce;
  List<String> _suggestions = <String>[];
  List<String> _recentSearches = <String>[];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isEmpty && widget.showRecentSearches) {
        setState(() {
          _showDropdown = true;
        });
      }
    } else {
      setState(() {
        _showDropdown = false;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    if (widget.showRecentSearches) {
      final recentSearches = await _searchService.getRecentSearches();
      if (!mounted) {
        return;
      }
      setState(() => _recentSearches = recentSearches);
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();

      if (trimmed.isNotEmpty && widget.showSuggestions) {
        _loadSuggestions(trimmed);
        return;
      }

      if (trimmed.isEmpty && widget.showRecentSearches) {
        setState(() {
          _suggestions = <String>[];
          _showDropdown = _recentSearches.isNotEmpty;
        });
        return;
      }

      setState(() {
        _suggestions = <String>[];
        _showDropdown = false;
      });
    });
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _showDropdown = suggestions.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = <String>[];
        _showDropdown = false;
      });
    }
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    widget.onSearch(trimmed);
    setState(() => _showDropdown = false);
    _focusNode.unfocus();
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    widget.onSuggestionTap?.call(suggestion);
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearch('');
                      setState(() {
                        _showDropdown = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 2,
              ),
            ),
          ),
          onChanged: _onTextChanged,
          onSubmitted: _performSearch,
        ),

        // Suggestions Dropdown
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Searches Section
                if (_controller.text.isEmpty && _recentSearches.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pencarian Terbaru',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await _searchService.clearRecentSearches();
                            await _loadRecentSearches();
                            if (!mounted) {
                              return;
                            }
                            setState(() => _showDropdown = false);
                          },
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._recentSearches.map(
                    (search) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.history,
                        size: 20,
                        color: AppColors.grey,
                      ),
                      title: Text(search),
                      onTap: () => _selectSuggestion(search),
                    ),
                  ),
                ],

                // Suggestions Section
                if (_suggestions.isNotEmpty) ...[
                  if (_controller.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Saran Pencarian',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ..._suggestions.map(
                    (suggestion) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.grey,
                      ),
                      title: Text(suggestion),
                      onTap: () => _selectSuggestion(suggestion),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
