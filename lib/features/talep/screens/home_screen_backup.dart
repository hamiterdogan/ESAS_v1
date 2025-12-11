// =====================================================
// YEDEK - Orijinal TalepTuruCard ve _AnaSayfaContent
// Bu dosya yedek olarak saklanmaktadır.
// Eski tasarıma dönmek için bu kodu home_screen.dart'a geri kopyalayın.
// =====================================================

/*
// Ana Sayfa içeriği (mevcut grid)
class _AnaSayfaContent extends ConsumerWidget {
  const _AnaSayfaContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talepTurleri = TalepTuru.getAll();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: talepTurleri.length,
        itemBuilder: (context, index) {
          final talep = talepTurleri[index];
          return TalepTuruCard(talep: talep);
        },
      ),
    );
  }
}

class TalepTuruCard extends ConsumerWidget {
  final TalepTuru talep;

  const TalepTuruCard({Key? key, required this.talep}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.go(talep.routePath);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.primaryGradient,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(talep.icon, size: 44, color: Colors.white),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  talep.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
