import 'package:url_launcher/url_launcher.dart';
import '../models/visitor.dart';
import '../models/message_template.dart';
import 'package:intl/intl.dart';

class WhatsappService {
  Future<void> sendTemplateMessage(Visitor visitor, MessageTemplate template) async {
    String message = template.content;
    
    // Remplacement des variables
    final prenom = visitor.nomComplet.split(' ').first;
    final nom = visitor.nomComplet;
    final date = DateFormat('dd/MM/yyyy').format(visitor.dateEnregistrement);
    
    message = message.replaceAll('[Prénom]', prenom)
                     .replaceAll('[Nom]', nom)
                     .replaceAll('[Date]', date);
                     
    await openWhatsApp(visitor.telephone, message);
  }

  Future<void> openWhatsApp(String phone, String message) async {
    // Nettoyage basique
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Ajout indicatif par défaut si manquant (suppose Gabon par défaut, +241)
    // TODO: Rendre configurable ou basé sur la locale
    if (!cleanPhone.startsWith('+') && !cleanPhone.startsWith('00')) {
      if (cleanPhone.length == 10) {
        // Format local 10 chiffres? ou 9 avec O devant
        cleanPhone = '+241$cleanPhone';
      } else if (cleanPhone.length == 8) {
         // Format standard Gabon (8 chiffres sans le 0 ou ancien?)
         // Note: Gabon est passé à 9 chiffres (0 + 8 chiffres) en 2019
         // Si l'utilisateur met 8 chiffres, on suppose qu'il manque le préfixe
        cleanPhone = '+241$cleanPhone';
      } else if (cleanPhone.length == 9) {
        // Format actuel 9 chiffres (ex: 066...)
        // Le visiteur saisit "066 85 18 18", on retire le 0 pour WhatsApp: +241 66...
        cleanPhone = '+241${cleanPhone.substring(1)}'; 
      }
    }
    
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d\'ouvrir WhatsApp';
    }
  }
}
