# Unshaky
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=JLLGBFQKTTX9W&source=url) [![Github All Releases](https://img.shields.io/github/downloads/aahung/Unshaky/total.svg)](https://github.com/aahung/Unshaky/releases) [![Build Status](https://travis-ci.org/aahung/Unshaky.svg?branch=master)](https://travis-ci.org/aahung/Unshaky)

![Menubar](README/menubar.png)

**Unshaky** tries to address an issue on the butterfly keyboard (Macbook & MacBook Pro 2016 or later): Double Key Press (See "User complaints" below). 

Apple made it difficult to replace only the keyboard and it costs hundreds of dollars. **Unshaky** might save your keyboard by dismissing such "second key hits" (any key presses that occur no later than x milliseconds after the previous effective one). I fixed my "w" key with **Unshaky**, and if it does not work for you, open an issue [here](https://github.com/aahung/Unshaky/issues). The image below illustrates how Unshaky works.

![How Unshaky works](README/how-unshaky-works.png)

[June 2018] Good news, Apple launched a [Keyboard Service Program for MacBook and MacBook Pro](https://www.apple.com/ca/support/keyboard-service-program-for-macbook-and-macbook-pro/), and go get your keyboard fixed, maybe temporarily.

## Complaints about this issue

- [Keyboard 'B' key double hit problem](https://www.ifixit.com/Answers/View/402016/Keyboard+%27B%27+key+double+hit+problem)
- [MacBook Pro 2016 Random Key Repeat Keyboard Issue](https://discussions.apple.com/thread/7840547)
- [MacBook Pro 13" 2016 Double Key Press](https://forums.macrumors.com/threads/macbook-pro-13-2016-double-key-press.2025843/)
- [1 key - 2 letters macbook pro 2016 and 2017](https://apple.stackexchange.com/questions/293523/1-key-2-letters-macbook-pro-2016-and-2017)
- [The new and improved MacBook keyboards have the same old problems](https://theoutline.com/post/6409/the-new-and-improved-macbook-keyboards-have-the-same-old-problems?zd=1&zi=4qyu5ngi)
- [Reddit: MBP 2018 15" Sticky Key Problem!](https://www.reddit.com/r/macbook/comments/9n8qkg/mbp_2018_15_sticky_key_problem/)
- [Reddit: My Experience with Macbook Pro 2018 Keyboard](https://www.reddit.com/r/macbook/comments/9n8hgi/my_experience_with_macbook_pro_2018_keyboard/)
- [Reddit: Anyone. with heir MBP 2018. keyboard. that. had. problems but is getting worse? Does a keyboard cover fix this?](https://www.reddit.com/r/macbookpro/comments/a1yul8/anyone_with_heir_mbp_2018_keyboard_that_had/)
- [Reddit: 2018 Known Keyboard Issue - repeating/sticky keys, silicone covers, compressed air](https://www.reddit.com/r/macbookpro/comments/a5jzyu/2018_known_keyboard_issue_repeatingsticky_keys/)
- [Apple Discussion: MacBook Pro 15" (2018) Keyboard "t" key repeating issue?](https://discussions.apple.com/thread/8536157) (55K have this question too on Feb 22, 2019)
- [Reddit: MacBook Air 2018 keyboard problem](https://www.reddit.com/r/macbookair/comments/ak9ptt/macbook_air_2018_keyboard_problem/)

## How-To (Video Walkthrough)

Click the image below to watch it on YouTube

[![How to install and setup Unshaky](https://img.youtube.com/vi/ppaeCBLCfu0/0.jpg)](http://www.youtube.com/watch?v=ppaeCBLCfu0 "How to install and setup Unshaky")

Can't watch by clicking the image above? [Download mp4 (13MB) file here](https://files.nestederror.cf/file/-public-/How%20to%20install%20and%20setup%20Unshaky.mp4)

## How-To

[Download Unshaky.app here](https://github.com/aahung/Unshaky/releases)

First, move the "Unshaky.app" to your "/Applications" folder.

### Grant Accessibility Permission

Follow the instruction when you first open Unshaky. If the instruction does not work for you, go to System Preferences -> Security & Privacy -> Privacy (Tab) -> Accessibility (Left panel) and add "Unshaky.app." Make sure it is checked.

![Grant Accessibility Permission](README/how-to-1.png)

### Launch at Startup (Optional)

Go to System Preferences -> Users & Groups -> Login Items (Tab) and add "Unshaky.app".

![Grant Accessibility Permission](README/how-to-2.png)

### Configure delays for your defective keys

Click Unshaky icon in the menu bar and select "Configure" to configure delays for the defective keys.

#### How to pick an appropriate delay?

I don't think there is a universal delay value for all people. If you type very fast, you might want to have a shorter delay. I use 40 ms since I am a fast typer. With a long delay, I cannot type "apple" because the second "p" is likely to be blocked. Some users found 60 ms a sweet spot and some have no issue with 80 ms. My suggestion is to start with a short delay (like 40 ms) and gradually increase it.

## Contributors

Please help to translate Unshaky into more languages. [Open an issue](https://github.com/aahung/Unshaky/issues/new/choose) to propose a new translation if you are interested.

- Main program, Chinese translation: [_sam](https://nestederror.com)
- Japanese: forgazer (translation), [HackingGate](https://github.com/HackingGate)
- French translation: [xuesongTU](https://github.com/xuesongTU)
- German translation: [Felix Grund](https://github.com/ataraxie)
- Russian and Ukrainian translation: [Alexey Khromets](https://github.com/akhromets)
- Turkish translation: [Hazar Ekinci](https://github.com/hazar-e)
- Korean translation: [Woosuk Park](https://github.com/readingsnail)
- Portuguese (Portugal) translation: [Gonçalo Matos](https://github.com/GoncaloCdM)
- Italian translation: [valepert](https://github.com/valepert), [Domenico Corvasce](https://github.com/domcorvasce)
- Indonesian translation: [Elmo Tanu Miharja](https://github.com/elmotan95)
- Spanish (Latin America) translation: [jadraker](https://github.com/jadraker)
