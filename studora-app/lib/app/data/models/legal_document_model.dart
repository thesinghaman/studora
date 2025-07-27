class LegalDocumentModel {
  final String id;
  final String docType;
  final String title;
  final String content;
  final DateTime lastUpdated;
  final String? version;
  List<Map<String, String>> parsedSections;
  LegalDocumentModel({
    required this.id,
    required this.docType,
    required this.title,
    required this.content,
    required this.lastUpdated,
    this.version,
    this.parsedSections = const [],
  });
  factory LegalDocumentModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    String rawContent = json['content'] as String? ?? '';
    LegalDocumentModel model = LegalDocumentModel(
      id: documentId,
      docType: json['docType'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'No Title',
      content: rawContent,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
                DateTime.now()
          : DateTime.now(),
      version: json['version'] as String?,
    );
    model._parseContentToSections();
    return model;
  }
  void _parseContentToSections() {
    final List<Map<String, String>> sections = [];
    final lines = content.split('\n');
    String currentSectionTitle = "";
    StringBuffer currentSectionContent = StringBuffer();
    String? docStatusText;
    if (lines.isNotEmpty &&
        lines.first.toLowerCase().startsWith("last updated")) {
      docStatusText = lines.first.trim();
      lines.removeAt(0);
      while (lines.isNotEmpty && lines.first.trim().isEmpty) {
        lines.removeAt(0);
      }
    }
    final RegExp mainSectionHeaderRegex = RegExp(
      r"^\d+\.\s+([A-Za-z\s&()/-]+)",
    );
    for (String line in lines) {
      String trimmedLine = line.trim();
      Match? headerMatch = mainSectionHeaderRegex.firstMatch(trimmedLine);
      if (headerMatch != null) {
        if (currentSectionTitle.isNotEmpty &&
            currentSectionContent.toString().trim().isNotEmpty) {
          sections.add({
            'title': currentSectionTitle,
            'content': currentSectionContent.toString().trimRight(),
          });
        }
        currentSectionTitle = headerMatch.group(0)!.trim();
        currentSectionContent = StringBuffer();
        String restOfLine = trimmedLine
            .substring(currentSectionTitle.length)
            .trim();
        if (restOfLine.isNotEmpty) {
          currentSectionContent.writeln(restOfLine);
        }
      } else {


        currentSectionContent.writeln(line);
      }
    }
    if (currentSectionTitle.isNotEmpty &&
        currentSectionContent.toString().trim().isNotEmpty) {
      sections.add({
        'title': currentSectionTitle,
        'content': currentSectionContent.toString().trimRight(),
      });
    }
    if (docStatusText != null) {


      sections.insert(0, {
        'title': "Document Status",
        'content': docStatusText,
      });
    }
    parsedSections = sections;
  }
}
