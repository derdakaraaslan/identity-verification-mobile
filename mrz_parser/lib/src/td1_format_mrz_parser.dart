import "dart:convert";
// import "package:http/http.dart" as http;
part of mrz_parser;

class _TD1MRZFormatParser {
  _TD1MRZFormatParser._();
  static const _linesLength = 30;
  static const _linesCount = 3;

  static bool isValidInput(List<String> input) =>
      input.length == _linesCount &&
      input.every((s) => s.length == _linesLength);

  static MRZResult parse(List<String> input) {
    if (!isValidInput(input)) {
      throw const InvalidMRZInputException();
    }

    final firstLine = input[0];
    final secondLine = input[1];
    final thirdLine = input[2];

    final documentTypeRaw = firstLine.substring(0, 2);
    final countryCodeRaw = firstLine.substring(2, 5);
    var documentNumberRaw = firstLine.substring(5, 14);
    print(documentNumberRaw[1].runtimeType);
    print(documentNumberRaw[1]);
    var secondChar = _makeDigit(documentNumberRaw[1]);
    
    var thirdChar = _makeDigit(documentNumberRaw[2]);
    var fourthChar = _makeLetter(documentNumberRaw[3]);
    documentNumberRaw =
        "${documentNumberRaw[0]}$secondChar$thirdChar$fourthChar${documentNumberRaw.substring(4)}";
    final documentNumberCheckDigitRaw = firstLine[14];
    final optionalDataRaw = firstLine.substring(15, 30);
    final birthDateRaw = secondLine.substring(0, 6);
    final birthDateCheckDigitRaw = secondLine[6];
    final sexRaw = secondLine.substring(7, 8);
    final expiryDateRaw = secondLine.substring(8, 14);
    final expiryDateCheckDigitRaw = secondLine[14];
    final nationalityRaw = secondLine.substring(15, 18);
    final optionalData2Raw = secondLine.substring(18, 29);
    final finalCheckDigitRaw = secondLine[29];
    final namesRaw = thirdLine.substring(0, 30);

    final documentTypeFixed =
        MRZFieldRecognitionDefectsFixer.fixDocumentType(documentTypeRaw);
    final countryCodeFixed =
        MRZFieldRecognitionDefectsFixer.fixCountryCode(countryCodeRaw);
    final documentNumberFixed = documentNumberRaw;
    final documentNumberCheckDigitFixed =
        MRZFieldRecognitionDefectsFixer.fixCheckDigit(
            documentNumberCheckDigitRaw);
    final optionalDataFixed = optionalDataRaw;
    final birthDateFixed =
        MRZFieldRecognitionDefectsFixer.fixDate(birthDateRaw);
    final birthDateCheckDigitFixed =
        MRZFieldRecognitionDefectsFixer.fixCheckDigit(birthDateCheckDigitRaw);
    final sexFixed = MRZFieldRecognitionDefectsFixer.fixSex(sexRaw);
    final expiryDateFixed =
        MRZFieldRecognitionDefectsFixer.fixDate(expiryDateRaw);
    final expiryDateCheckDigitFixed =
        MRZFieldRecognitionDefectsFixer.fixCheckDigit(expiryDateCheckDigitRaw);
    final nationalityFixed =
        MRZFieldRecognitionDefectsFixer.fixNationality(nationalityRaw);
    final optionalData2Fixed = optionalData2Raw;
    final finalCheckDigitFixed =
        MRZFieldRecognitionDefectsFixer.fixCheckDigit(finalCheckDigitRaw);
    final namesFixed = MRZFieldRecognitionDefectsFixer.fixNames(namesRaw);

    final documentNumberIsValid = int.tryParse(documentNumberCheckDigitFixed) ==
        MRZCheckDigitCalculator.getCheckDigit(documentNumberFixed);

    if (!documentNumberIsValid) {
      throw const InvalidDocumentNumberException();
    }

    final birthDateIsValid = int.tryParse(birthDateCheckDigitFixed) ==
        MRZCheckDigitCalculator.getCheckDigit(birthDateFixed);

    if (!birthDateIsValid) {
      throw const InvalidBirthDateException();
    }

    final expiryDateIsValid = int.tryParse(expiryDateCheckDigitFixed) ==
        MRZCheckDigitCalculator.getCheckDigit(expiryDateFixed);

    if (!expiryDateIsValid) {
      throw const InvalidExpiryDateException();
    }

    final finalCheckStringFixed =
        '$documentNumberFixed$documentNumberCheckDigitFixed'
        '$optionalDataFixed'
        '$birthDateFixed$birthDateCheckDigitFixed'
        '$expiryDateFixed$expiryDateCheckDigitFixed'
        '$optionalData2Fixed';
    final finalCheckStringIsValid = int.tryParse(finalCheckDigitFixed) ==
        MRZCheckDigitCalculator.getCheckDigit(finalCheckStringFixed);

    if (!finalCheckStringIsValid) {
      throw const InvalidMRZValueException();
    }

    final documentType = MRZFieldParser.parseDocumentType(documentTypeFixed);
    final countryCode = MRZFieldParser.parseCountryCode(countryCodeFixed);
    final documentNumber =
        MRZFieldParser.parseDocumentNumber(documentNumberFixed);
    final optionalData = MRZFieldParser.parseOptionalData(optionalDataFixed);
    final birthDate = MRZFieldParser.parseBirthDate(birthDateFixed);
    final sex = MRZFieldParser.parseSex(sexFixed);
    final expiryDate = MRZFieldParser.parseExpiryDate(expiryDateFixed);
    final nationality = MRZFieldParser.parseNationality(nationalityFixed);
    final optionalData2 = MRZFieldParser.parseOptionalData(optionalData2Fixed);
    final names = MRZFieldParser.parseNames(namesFixed);
    final namess = names[0];
    final namesss = names[1];

    return MRZResult(
      documentType: documentType,
      countryCode: countryCode,
      surnames: names[0],
      givenNames: names[1],
      documentNumber: documentNumber,
      nationalityCountryCode: nationality,
      birthDate: birthDate,
      sex: sex,
      expiryDate: expiryDate,
      personalNumber: optionalData,
      personalNumber2: optionalData2,
    );
//     void main() async{ 
//       var identityInfo = {'Document type': "$documentType",'Country code':"$countryCode", "Surname": "$namess", "Given name": "$namesss", "Document number": "$documentNumber", "Nationality Code": "$nationality", "Birthdate": "$birthDate", "Sex": "$sex", "Expriy Date": "$expiryDate", "Personal Number": "$optionalData", "Personal Number 2": "$optionalData2"}; 
// }
//     final url="http://127.0.0.1:8000/post";
//             var response = await http.post(
//                   //final url="http://127.0.0.1:8000/process/dc2f95db-f392-4a03-8e9f-1619bf5799a1";
//                   Uri.parse(url),
//                   body: {"key1": "Value 1"}
//                );

}
} 
  

  String _makeLetter(String char) {
    switch (char) {
      case "0":
        return "O";

      default:
        return char;
    }
  }

  String _makeDigit(String char) {
    switch (char) {
      case "0":
      case "O":
      case "D":
      case "B":
        return "0";

      default:
        return char;
    }
  }

