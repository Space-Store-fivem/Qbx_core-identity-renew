Claro, vamos refinar a mensagem de anúncio e depois detalhar a implementação do sistema de fotos, que é uma excelente adição para a imersão.

Mensagem de Atualização para a Comunidade MRI
Aqui está uma versão aprimorada do anúncio, com um tom mais alinhado a uma comunidade de desenvolvimento e focada nos "porquês" das mudanças.

🚀 Atualização de Framework no MRI: Interatividade e Roleplay Aprimorados! 🚀
Olá, comunidade MRI!

Temos o prazer de anunciar uma atualização importante no qbx_core, projetada para substituir sistemas automáticos por mecânicas que incentivam e dependem da interação direta entre os jogadores. O objetivo é claro: fortalecer o roleplay e dar mais poder e propósito às ações dentro do jogo.

Confira o que foi implementado:

📜 Sistema de Identidade Agora é Manual e Interativo
A emissão de identidades foi completamente reformulada. A automação deu lugar à interação:

Status de "Indigente": Novos jogadores não recebem mais uma identidade automaticamente. Eles começam como "Indigentes", precisando de um registro oficial para serem reconhecidos pelo Estado.

Emissão por um Policial (Player): Para obter uma identidade, o cidadão deve procurar um Policial Federal. Este processo agora é uma interação direta, onde o policial é responsável por todo o procedimento.

Foto para o MDT: O processo de registro agora inclui um passo crucial: o policial deve tirar uma foto do cidadão. Essa foto se torna o registro visual oficial no MDT, tornando investigações e verificações muito mais autênticas.

👮 Novas Ferramentas para a Força Policial
Para dar suporte a esse novo sistema, a polícia agora tem acesso a comandos específicos:

/abordar: Permite que um policial imobilize um jogador próximo e verifique instantaneamente seu ID, CitizenID e se ele possui uma identidade registrada ou se é indigente.

/registraridentidade [ID]: Inicia o processo de registro, que culmina na fotografia e emissão do documento.

/verificarid [ID]: Consulta rapidamente o status de um cidadão para saber se ele já foi registrado no sistema.

Essas mudanças representam nosso compromisso em criar uma base cada vez mais robusta e focada em um roleplay de alta qualidade.

Agradecemos a todos os membros da comunidade MRI pelo contínuo apoio e feedback!

Implementando o Sistema de Foto para Identidade
Este recurso é um pouco mais complexo e requer um script para capturar e enviar a tela. A maneira mais comum é usar o screenshot-basic e um Webhook do Discord.

Pré-requisitos:
Tenha o script screenshot-basic instalado no seu servidor.

Crie um Webhook em um canal do seu Discord e copie a URL.

No seu server.cfg, adicione a seguinte linha (substitua pela sua URL):

Snippet di codice

set webhook_identidade "URL_DO_SEU_WEBHOOK_AQUI"
Passo 1: Criar o Comando de Registro (Lado do Servidor)
Este comando iniciará o processo. Abra qbx_core/server/commands.lua e adicione:

Lua

lib.addCommand('registraridentidade', {
    help = 'Inicia o processo de registro de identidade para um cidadão.',
    params = {{ name = 'id', type = 'playerId', help = 'ID do cidadão.' }},
    restricted = 'job.police' -- Mude 'police' se o nome do trabalho for outro
}, function(source, args, raw)
    local targetId = tonumber(args.id)
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'ID inválido.', 'error')
        return
    end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Este cidadão não está na cidade.', 'error')
        return
    end

    if targetPlayer.Functions.GetMetaData('has_identity') then
        TriggerClientEvent('QBCore:Notify', source, 'Este cidadão já possui uma identidade registrada!', 'error')
        return
    end

    -- Avisa o policial para tirar a foto
    TriggerClientEvent('QBCore:Notify', source, 'Aproxime-se do cidadão e prepare-se para tirar a foto. O sistema será acionado.', 'primary')
    -- Aciona o evento no cliente do policial para iniciar o processo de fotografia
    TriggerClientEvent('qbx_core:client:startIdentityPhotoProcess', source, targetId)
end)
Passo 2: Lógica da Foto (Lado do Cliente)
Este código irá capturar a tela e enviar para o servidor. Coloque-o no arquivo qbx_core/client/commands.lua que criamos anteriormente.

Lua

RegisterNetEvent('qbx_core:client:startIdentityPhotoProcess', function(targetId)
    Wait(2000) -- Pequeno delay para o policial se posicionar
    
    exports['screenshot-basic']:requestScreenshotUpload(GetConvar("webhook_identidade", ""), "file", function(data)
        local response = json.decode(data)
        if response and response.attachments and response.attachments[1] then
            local photoUrl = response.attachments[1].url
            -- Envia a URL da foto para o servidor para finalizar o registro
            TriggerServerEvent('qbx_core:server:completeIdentityRegistration', targetId, photoUrl)
            TriggerEvent('QBCore:Notify', 'Foto enviada para o sistema. Finalizando registro...', 'primary')
        else
            TriggerEvent('QBCore:Notify', 'Falha ao fazer o upload da foto. Verifique o webhook.', 'error')
        end
    end)
end)
Passo 3: Finalizar o Registro (Lado do Servidor)
Este evento recebe a URL da foto e salva tudo. Adicione-o ao arquivo qbx_core/server/events.lua.

Lua

RegisterNetEvent('qbx_core:server:completeIdentityRegistration', function(targetId, photoUrl)
    local source = source -- O ID do policial que executou o comando
    local targetPlayer = exports.qbx_core:GetPlayer(targetId)

    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'O cidadão saiu da cidade durante o processo.', 'error')
        return
    end

    -- Salva a URL da foto e define que o jogador agora tem identidade
    targetPlayer.Functions.SetMetaData('photo_url', photoUrl)
    targetPlayer.Functions.SetMetaData('has_identity', true)

    -- Dá o item da identidade
    exports.ox_inventory:AddItem(targetPlayer.PlayerData.source, 'id_card', 1)
    
    -- Salva os dados permanentemente
    targetPlayer.Functions.Save()

    -- Notificações de sucesso
    TriggerClientEvent('QBCore:Notify', source, 'Identidade registrada com sucesso para o cidadão ' .. targetId, 'success')
    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Sua identidade foi registrada e emitida por um Policial Federal.', 'success')
end)
Passo 4: Exibir a Foto no MDT
Por fim, você precisa que seu MDT mostre essa foto. No arquivo JavaScript do seu MDT, encontre a função que exibe os dados do cidadão e adicione uma lógica para carregar a imagem.

Exemplo (JavaScript do MDT):

JavaScript

// Dentro da função que preenche os dados do cidadão no MDT
function setupCitizenProfile(citizenData) {
    // ... outro código que preenche nome, etc.

    // Lógica para a foto
    if (citizenData.metadata.photo_url) {
        // Se existe uma URL da foto, exiba-a
        // Assumindo que você tenha um elemento <img> com o id="citizen-photo" no seu HTML
        $("#citizen-photo").attr("src", citizenData.metadata.photo_url);
    } else {
        // Se não, mostre uma imagem padrão
        $("#citizen-photo").attr("src", "images/default_profile.png");
    }

    // ... restante do código
}









_<p align="center">"And then there was Qbox"</p>_


# qbx_core

qbx_core is a framework created on September 27, 2022, as a successor to qb-core and continues the development of a solid foundation for building easy-to-use, performant, and secure server resources.

Want to know more? View our [documentation](https://qbox-project.github.io/)

# Features

- **Bridge layer provides Backwards compatibility with Most QB Resources with 0 effort required**
- Built-in multicharacter
- Built-in multi-job/gang
- Built-in queue system for full servers
- Persistent player vehicles
- Export based API to read/write core data

## Modules
The core makes available several optional modules for developers to import into their resources:
- Hooks: For developers to provide Ox style hooks to extend the functionality of their resources
- Logger: Can log to either discord, or Ox's logger through one interface
- Lib: Common functions for tables, strings, math, native audio, vehicles, and drawing text.

# Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

#

⚠️We advise not modifying the core outside of the config files⚠️

If you feel something is missing or want to suggest additional functionality that can be added to qbx_core, bring it up on the official [Qbox Discord](https://discord.gg/qbox)!

Thank you to everyone and their contributions (large or small!), as this wouldn't have been possible.
