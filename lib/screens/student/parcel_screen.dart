import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/parcel_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/aurora_scaffold.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/staggered_animation.dart';

class ParcelScreen extends StatelessWidget {
  const ParcelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;
    if (user == null) return const AuroraScaffold(body: Center(child: CircularProgressIndicator()));

    return AuroraScaffold(
      appBar: GlassAppBar(title: 'My Parcels'),
      body: SafeArea(
        child: StreamBuilder<List<ParcelModel>>(
          stream: context.read<ParcelProvider>().getStudentParcels(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final items = snapshot.data ?? [];
            if (items.isEmpty)
              return Center(child: Text('No parcels found', style: TextStyle(color: Colors.white.withOpacity(0.5))));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final p = items[i];
                final collected = p.status == 'collected';
                return StaggeredAnimation(
                  delay: Duration(milliseconds: i * 60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (collected ? Colors.grey : const Color(0xFF34D399)).withOpacity(0.15),
                              ),
                              child: Icon(Icons.local_shipping_outlined,
                                  color: collected ? Colors.grey : const Color(0xFF34D399), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.courierName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Tracking: ${p.trackingNumber}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                              Text('Arrived: ${Helpers.formatDate(p.arrivedAt)}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (collected ? Colors.grey : const Color(0xFF34D399)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(p.status.toUpperCase(),
                                  style: TextStyle(
                                      color: collected ? Colors.grey : const Color(0xFF34D399),
                                      fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          if (p.imageUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(p.imageUrl,
                                  height: 130, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
