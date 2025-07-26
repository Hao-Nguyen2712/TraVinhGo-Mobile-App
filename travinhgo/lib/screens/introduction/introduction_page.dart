import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final String title = 'Chào mừng bạn đến với TraVinhGo';
  final String contentFirst = """
<p><strong>Trà Vinh</strong> 🌴 là một thành phố của sự xinh đẹp, là mảnh đất màu mỡ mà ít người để ý. Hãy cùng <strong>TraVinhGo</strong> khám phá <strong>Trà Vinh</strong> nhé!</p>
<p><strong>Trà Vinh</strong> là tỉnh thuộc vùng <strong>Duyên hải Đồng bằng sông Cửu Long</strong>, tiếp giáp với các tỉnh <strong>Bến Tre</strong> 🥥, <strong>Vĩnh Long</strong> 🏞️, <strong>Sóc Trăng</strong> 🛕, nằm giữa hai con sông lớn là <strong>sông Tiền</strong> và <strong>sông Hậu</strong> 🌊.</p>
<p>Trung tâm tỉnh lỵ <strong>Trà Vinh</strong> cách <strong>Thành phố Hồ Chí Minh</strong> 🏙️ 130 km và <strong>Thành phố Cần Thơ</strong> 100 km.</p>
<p>Tỉnh <strong>Trà Vinh</strong> gồm có:</p>
<ul>
<li>01 thành phố: <strong>Thành phố Trà Vinh</strong></li>
<li>01 thị xã: <strong>Thị xã Duyên Hải</strong></li>
<li>07 huyện: <strong>Càng Long</strong>, <strong>Châu Thành</strong>, <strong>Tiểu Cần</strong>, <strong>Cầu Kè</strong>, <strong>Trà Cú</strong>, <strong>Cầu Ngang</strong>, <strong>Duyên Hải</strong></li>
</ul>
<p>Tổng diện tích sau khi sáp nhập là <strong>15,73 km²</strong> với dân số khoảng <strong>45.397 người</strong>, gồm các dân tộc chính: <strong>Kinh</strong>, <strong>Khmer</strong>, <strong>Hoa</strong> 🧑‍🤝‍🧑.</p>
<p>Với vị trí tiếp giáp <strong>Biển Đông</strong> 🐚 cùng chiều dài bờ biển 65 km, vùng đất <strong>Trà Vinh</strong> bao gồm:</p>
<ul>
<li>vùng đất châu thổ lâu đời</li>
<li>vùng đất trẻ mới bồi</li>
<li>mạng lưới sông ngòi chằng chịt 🌾, mang nặng phù sa, bồi đắp cho những vườn cây ăn trái 🌳🍊</li>
</ul>
<p><strong>Trà Vinh</strong> là tỉnh <em>mưa thuận, gió hòa</em> 🌦️, nhiệt độ trung bình từ <strong>26–27°C</strong> 🌡️, hiếm khi có bão. Vì thế, bất cứ mùa nào trong năm, du khách cũng có thể đến <strong>miền Duyên hải</strong> để trải nghiệm.</p>
""";
  final String contentSecond =  """
<p><strong>TraVinhGo</strong> 📱 là một ứng dụng đa ngôn ngữ giúp khám phá <strong>Trà Vinh</strong> bằng bản đồ số 🗺️, tạo một trải nghiệm dễ dàng và tiện dụng để người dùng kết nối đến các địa điểm du lịch 🏖️, đặc sản địa phương 🍲, sản phẩm <strong>OCOP</strong> 🛍️ và các sự kiện 🎉 trên địa bàn <strong>Trà Vinh</strong>.</p>

<p><strong>TraVinhGo</strong> cung cấp nhiều địa điểm du lịch và thông tin chính xác, kèm theo hình ảnh 📸 và bản đồ 🧭 để bạn khám phá theo sở thích của mình.</p>

<p>Phần <strong>đặc sản địa phương</strong> 🍛 cũng sẽ được cung cấp thông tin chi tiết và các địa điểm bán trên bản đồ 🗺️, giúp bạn dễ dàng đến tận nơi và mua chúng một cách thuận tiện.</p>

<p>Sản phẩm <strong>OCOP</strong> 🛒 cũng tương tự — được giới thiệu với thông tin chính xác và hiển thị địa điểm bán cụ thể, giúp bạn dễ dàng tìm và mua những sản phẩm chất lượng tại <strong>Trà Vinh</strong>.</p>

<p>Cuối cùng là phần <strong>sự kiện và lễ hội</strong> 🎊, được cập nhật hàng ngày 📅 với thông tin rõ ràng, giúp người dùng theo dõi các hoạt động văn hóa, giải trí của <strong>Trà Vinh</strong> một cách sinh động và trực quan.</p>
""";
  
  final String thankContent = """
<p>🙏 <strong>Cảm ơn bạn</strong> đã tải ứng dụng <strong>TràVinhGo</strong> của chúng tôi!</p>
<p>Chúng tôi chúc bạn tận hưởng chuyến du lịch của mình một cách <strong>trọn vẹn nhất</strong> 🧳 cùng với <strong>TraVinhGo</strong> 🌟.</p>
<p>Trong quá trình sử dụng ứng dụng, nếu có bất kỳ vấn đề nào 🛠️, hãy <strong>đóng góp ý kiến</strong> thông qua phần <strong>Phản hồi</strong> 📩 ở bên <strong>Hồ sơ</strong> 👤 để chúng tôi có thể cải thiện và phục vụ bạn tốt hơn.</p>
<p>💚 Chúc bạn có một hành trình đầy trải nghiệm và niềm vui tại <strong>Trà Vinh</strong>!</p>
""";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.introduce),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Html(
                  data: contentFirst,
                  style: _htmlStyle(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/introduction/gocconchim.png",
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 5,),
                      Text('Một góc Cồn Chim', style: TextStyle(fontStyle: FontStyle.italic),)
                    ],
                  )
                ),
                Html(
                  data: contentSecond,
                  style: _htmlStyle(context),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images/introduction/thienvientruclam.png",
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 5,),
                        Text('Thiền viện Trúc Lâm (Ảnh: Dương Văn Hưởng)', style: TextStyle(fontStyle: FontStyle.italic),)
                      ],
                    )
                ),
                Html(
                  data: thankContent,
                  style: _htmlStyle(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Style> _htmlStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return {
      "body": Style(
        fontSize: FontSize(16.0),
        lineHeight: LineHeight(1.5),
        color: colorScheme.onSurface,
      ),
      "p": Style(margin: Margins.only(bottom: 10)),
      "strong": Style(fontWeight: FontWeight.bold),
      "em": Style(fontStyle: FontStyle.italic),
      "u": Style(textDecoration: TextDecoration.underline),
      "h1": Style(
        fontSize: FontSize.xxLarge,
        fontWeight: FontWeight.bold,
        margin: Margins.symmetric(vertical: 10),
      ),
      "h2": Style(
        fontSize: FontSize.xLarge,
        fontWeight: FontWeight.w600,
        margin: Margins.symmetric(vertical: 8),
      ),
      "h3": Style(
        fontSize: FontSize.large,
        fontWeight: FontWeight.w500,
        margin: Margins.symmetric(vertical: 6),
      ),
      "blockquote": Style(
        fontStyle: FontStyle.italic,
        padding: HtmlPaddings.symmetric(horizontal: 15, vertical: 8),
        margin: Margins.symmetric(vertical: 10),
        backgroundColor: colorScheme.surfaceVariant,
        border: Border(left: BorderSide(color: colorScheme.outline, width: 4)),
      ),
      "ul": Style(margin: Margins.only(left: -20, bottom: 10)),
      "ol": Style(margin: Margins.only(left: -20, bottom: 10)),
      "li": Style(padding: HtmlPaddings.symmetric(vertical: 2)),
      "a": Style(
        color: colorScheme.primary,
        textDecoration: TextDecoration.underline,
      ),
      "table": Style(
          border: Border.all(color: colorScheme.outline.withOpacity(0.5))),
      "th": Style(
        padding: HtmlPaddings.all(6),
        backgroundColor: colorScheme.surfaceVariant,
        fontWeight: FontWeight.bold,
      ),
      "td": Style(
        padding: HtmlPaddings.all(6),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
    };
  }
}