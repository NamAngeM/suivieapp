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
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), ''); // Ne garde que les chiffres

    // Gère le format local Gabon (06..., 07...) vers +241
    if (cleanPhone.startsWith('0') && cleanPhone.length == 9) {
      // Ex: 062030405 -> +24162030405
      cleanPhone = '241${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('241')) {
      // Déjà 241
    } else if (cleanPhone.length == 8) {
      // Ancien format ou sans le 0 -> ajoute 241
      cleanPhone = '241$cleanPhone';
    } else {
      // Autre (suppose déjà format international ou autre pays)
      // Si pas d'indicatif, on force le 241 par défaut si < 9 chiffres ?
      if (cleanPhone.length <= 9 && !cleanPhone.startsWith('241')) {
         cleanPhone = '241$cleanPhone';
      }
    }
    
    // WhatsApp demande format sans +, juste les chiffres pays + tel
    // Mais wa.me accepte aussi, cependant la doc dit 'Use international format ... omit zeroes, brackets or dashes ... do not use leading +'.
    // Wait, wa.me wants: https://wa.me/24166000000 (No +)
    // Verification: https://faq.whatsapp.com/5913398998672934 => "Use: https://wa.me/15551234567" (No +).
    
    // Donc cleanPhone doit être: 241xxxxxxxxx
    if (cleanPhone.startsWith('+')) cleanPhone = cleanPhone.substring(1);
    
    // Safety check final: si ça ne marche pas, WhatsApp web propose de vérifier le numéro.
    // Pour le Gabon: 241 + (8 chiffres). Le 0 initial du format 9 chiffres doit virer.
    // Logic above:
    // Input: 074556677 (9 digits) -> remove 0 -> 74556677 -> add 241 -> 24174556677. Correct.
    // Input: +241074556677 -> handled? RegExp removed +. -> 241074556677. Not handled by 'startsWith 0'.
    // We should be careful about pre-formatted numbers.
    // Refined logic:
    // 1. Strip all non-digits.
    // 2. If starts with 241: check next digit. if 0, remove it? (Gabon specific? usually formatted as +241 07...)
    //    Actually, let's keep it simple. If starts with 0 and length 9 => replace 0 with 241.
    
    // Mise à jour robuste :
    cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanPhone.startsWith('0') && cleanPhone.length == 9) {
      cleanPhone = '241${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('241')) {
       // Si ne commence pas par 241, on ajoute 241 (sauf si semble être un autre code pays long? Non, on force Gabon pour l'app locale)
       cleanPhone = '241$cleanPhone';
    }
    // Si commence par 241, on laisse tel quel.
    
    // Correction spécifique: si le user a entré 24106... (avec le 0), il faut virer le 0 après le 241 ?
    // WhatsApp n'aime pas le 0 après le code pays.
    if (cleanPhone.startsWith('2410')) {
      cleanPhone = '241${cleanPhone.substring(4)}';
    }
    
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d\'ouvrir WhatsApp';
    }
  }
}
